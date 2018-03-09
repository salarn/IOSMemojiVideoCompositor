//
//  CustomVideoCompositor.swift
//  CustomVideoCompositor
//
//  Created by Salar on 11/16/16.
//  Copyright © 2016 Clay Garrett. All rights reserved.
//

import UIKit
import AVFoundation

class CustomVideoCompositor: NSObject, AVVideoCompositing {
    
    var duration: CMTime?
	var mainBuffer = UnsafeMutablePointer<CVPixelBuffer?>.allocate(capacity: 1)

	var frame : CGRect?
	var data : Data?
	var json : NSDictionary?
	var heightFrame : Int?
	var widthFrame : Int?
	var framesDetail : NSArray?
	var framesCount: Int?

	override init(){
		super.init()

		do {
			framesCount = 0
			self.data = try Data.init(contentsOf: URL(fileURLWithPath: "/Users/salar/Desktop/elf_boogie_dance_01.bundle/position_data.json" ) )
			self.json = try JSONSerialization.jsonObject(with: data!) as? NSDictionary

			self.heightFrame = self.json?["h"] as? Int
			self.widthFrame = self.json?["w"] as? Int
			self.framesDetail = ((self.json?["l"] as? NSArray)?[1] as? NSDictionary)?["f"] as? NSArray

			//let item1 = json?["l"] as! [NSDictionary]
			//let item2 = item1[1] as! [String: AnyObject]
			//print(self.framesDetail!)
		} catch{
			print("Can not load Json file!")
		}
	}

    var sourcePixelBufferAttributes: [String : Any]? {
        get {
            return ["\(kCVPixelBufferPixelFormatTypeKey)": kCVPixelFormatType_32BGRA]
        }
    }
    
    var requiredPixelBufferAttributesForRenderContext: [String : Any] {
        get {
            return ["\(kCVPixelBufferPixelFormatTypeKey)": kCVPixelFormatType_32BGRA]
        }
    }
    
    func renderContextChanged(_ newRenderContext: AVVideoCompositionRenderContext) {
        // do anything in here you need to before you start writing frames
    }

    func startRequest(_ request: AVAsynchronousVideoCompositionRequest) {
        // called for every frame
        // assuming there's a single video track. account for more complex scenarios as you need to
		if(request.compositionTime.value == 0){
			framesCount = 0
		}

        let buffer = request.sourceFrame(byTrackID: request.sourceTrackIDs[0].int32Value)
        let instruction = request.videoCompositionInstruction

		let inst = instruction as! WatermarkCompositionInstruction
		let image = inst.watermarkImage
		CVPixelBufferCreate(kCFAllocatorDefault, self.widthFrame! , self.heightFrame! , kCVPixelFormatType_32BGRA, nil , mainBuffer)

		CVPixelBufferLockBaseAddress(buffer!, CVPixelBufferLockFlags.readOnly)
		CVPixelBufferLockBaseAddress(mainBuffer.pointee! , CVPixelBufferLockFlags.readOnly)


		let bufferWidth = CVPixelBufferGetWidth(buffer!)
		let bufferHeight = CVPixelBufferGetHeight(buffer!)
		let bytesPerRow = CVPixelBufferGetBytesPerRow(buffer!)
		let baseAddress = CVPixelBufferGetBaseAddress(buffer!)!.assumingMemoryBound(to: UInt8.self)


		let baseAddressMain = CVPixelBufferGetBaseAddress(mainBuffer.pointee!)!.assumingMemoryBound(to: UInt8.self)

		for row in 0..<bufferHeight/2{
			var upperPixel = baseAddress.advanced(by: Int(row * bytesPerRow))
			var pixelMain = baseAddressMain.advanced(by: Int(row * bytesPerRow))
			for _ in 0..<bufferWidth{
				for i in 0...3 {
					pixelMain[i] = upperPixel[i]
				}
				pixelMain += 4
				upperPixel += 4
			}
		}

		let positionX = ((self.framesDetail?[self.framesCount!] as? NSDictionary)?["p"] as? NSArray)?[0] as? Double
		let positionY = ((self.framesDetail?[self.framesCount!] as? NSDictionary)?["p"] as? NSArray)?[1] as? Double
		var jawX = ((self.framesDetail?[self.framesCount!] as? NSDictionary)?["j"] as? NSArray)?[0] as? Double
		var jawY = 600.0 - (((self.framesDetail?[self.framesCount!] as? NSDictionary)?["j"] as? NSArray)?[1] as? Double)!
		let scaleWidth = ((self.framesDetail?[self.framesCount!] as? NSDictionary)?["s"] as? NSArray)?[0] as? Double
		let scaleHeight = ((self.framesDetail?[self.framesCount!] as? NSDictionary)?["s"] as? NSArray)?[1] as? Double
		let rotate = (((self.framesDetail?[self.framesCount!] as? NSDictionary)?["r"] as? Double)!/180.0)*M_PI
		let headWidth = 400.0*scaleWidth!/100.0
		let headHeight = 600.0*scaleHeight!/100.0
		jawX! *= scaleWidth!/100.0
		jawY *= scaleHeight!/100.0

		//self.frame = CGRect.init(x: -(headWidth/2.0), y: -(headHeight/2.0), width: headWidth, height: headHeight)
		self.frame = CGRect.init(x: -jawX!, y: -jawY, width: headWidth, height: headHeight)

		let newContext = CGContext.init(data: CVPixelBufferGetBaseAddress(mainBuffer.pointee!), width: CVPixelBufferGetWidth(mainBuffer.pointee!), height: CVPixelBufferGetHeight(mainBuffer.pointee!), bitsPerComponent: 12, bytesPerRow: CVPixelBufferGetBytesPerRow(mainBuffer.pointee!), space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
		//newContext?.translateBy(x: CGFloat(positionX!-jawX!+(headWidth/2.0)), y: CGFloat(positionY!-jawY+(headHeight/2.0)))
		newContext?.translateBy(x: CGFloat(positionX!), y: CGFloat(positionY!))
		newContext?.rotate(by: CGFloat(-rotate))
		newContext?.draw(image!, in: frame!)


		for row in 0..<bufferHeight/2{
			var upperPixel = baseAddress.advanced(by: Int(row * bytesPerRow))
			var lowerPixel = baseAddress.advanced(by: Int((row+bufferHeight/2) * bytesPerRow))
			var pixelMain = baseAddressMain.advanced(by: Int(row * bytesPerRow))
			for _ in 0..<bufferWidth{
				if (lowerPixel[0] > 100) {
					for i in 0...3 {
						pixelMain[i] = upperPixel[i]
					}
				}
				pixelMain += 4
				upperPixel += 4
				lowerPixel += 4
			}
		}

		CVPixelBufferUnlockBaseAddress(buffer!, CVPixelBufferLockFlags.readOnly)
		CVPixelBufferUnlockBaseAddress(mainBuffer.pointee!, CVPixelBufferLockFlags.readOnly)
		request.finish(withComposedVideoFrame: mainBuffer.pointee!)
		mainBuffer.deinitialize()
		self.framesCount! += 1
    }
    
    func cancelAllPendingVideoCompositionRequests() {
        // anything you want to do when the compositing is canceled
    }
}
