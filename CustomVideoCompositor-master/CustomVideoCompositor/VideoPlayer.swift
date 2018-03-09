//
//  VideoExporter.swift
//  AVPlayerLayerBug
//
//  Created by Salar on 10/28/16.
//  Copyright © 2016 Clay Garrett. All rights reserved.
//

import UIKit
import AVFoundation

class VideoPlayer: NSObject {

	var parentLayer: CALayer?
	var imageLayer: CALayer?
	//let videoUrl: URL = URL(fileURLWithPath: Bundle.main.path(forResource: "sorry", ofType: "mov")!)
	let videoUrl : URL = URL(fileURLWithPath: "/Users/salar/Desktop/template.mp4")
	let jsonUrl : URL = URL(fileURLWithPath: "/Users/salar/Desktop/santas-twerkshop-03.bundle/position_data.json")
	let image = UIImage(named: "bache.png")!.cgImage

	func play() -> AVPlayer{
		// remove existing export file if it exists
		/*let baseDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
		let exportUrl = (baseDirectory.appendingPathComponent("export.mov", isDirectory: false) as NSURL).filePathURL!
		*/
		let exportUrl = URL(fileURLWithPath: "/Users/salar/Desktop/export.mov")
		deleteExistingFile(url: exportUrl)

		// init variables
		let videoAsset: AVAsset = AVAsset(url: videoUrl) as AVAsset
		let tracks = videoAsset.tracks(withMediaType: AVMediaTypeVideo)
		let videoAssetTrack = tracks.first!

		// build video composition
		let videoComposition = AVMutableVideoComposition()
		videoComposition.customVideoCompositorClass = CustomVideoCompositor.self
		videoComposition.renderSize = CGSize(width: 400, height: 300)
		videoComposition.frameDuration = CMTimeMake(videoAssetTrack.minFrameDuration.value, videoAssetTrack.minFrameDuration.timescale)
		//CMTimeMake(videoAssetTrack.timeRange.duration.value , 21*videoAssetTrack.timeRange.duration.timescale)
		//print(videoAssetTrack.timeRange.duration)
		// build instructions
		let instructionTimeRange = CMTimeRangeMake(kCMTimeZero, videoAssetTrack.timeRange.duration)
		// we're overlaying this on our source video. here, our source video is 1080 x 1080
		// so even though our final export is 320 x 320, if we want full coverage of the video with our watermark,
		// then we need to make our watermark frame 1080 x 1080
		//let watermarkFrame = CGRect(x: 170, y: 120, width: 60, height: 60)
		let instruction = WatermarkCompositionInstruction(timeRange: instructionTimeRange, watermarkImage: image!)

		videoComposition.instructions = [instruction]



		let Player =  AVPlayer(playerItem: AVPlayerItem(asset: videoAsset))
		Player.currentItem?.videoComposition = videoComposition
		return Player
	}

	func deleteExistingFile(url: URL) {
		let fileManager = FileManager.default
		do {
			try fileManager.removeItem(at: url)
		}
		catch _ as NSError {

		}
	}
}
