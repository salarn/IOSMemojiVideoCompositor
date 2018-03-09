//
//  ViewController.swift
//  AVPlayerLayerBug
//
//  Created by Salar on 11/16/16.
//  Copyright © 2016 Clay Garrett. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {

	func loopVideo(videoPlayer: AVPlayer) {
		NotificationCenter.default.addObserver(forName: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object:videoPlayer.currentItem, queue: nil) { notification in
			videoPlayer.seek(to: kCMTimeZero)
			videoPlayer.play()
		}
	}
	override func viewDidAppear(_ animated: Bool) {
		self.RenderVideos()
	}

	func RenderVideos() {
		let Render = VideoPlayer()

		let PlayerView : AVPlayer = Render.play()
		//let PlayerView : AVPlayer = PlayerView(
		let PlayerLayer = AVPlayerLayer(player: PlayerView)
		//let image = UIImage(named: "bache.png")!
		//let imageView = UIImageView.init(image: image)
		//self.view.addSubview(imageView)
		
		PlayerLayer.frame = CGRect(x: 0, y: 0, width: 400, height: 300)
		self.view.layer.addSublayer(PlayerLayer)
		PlayerView.play()
		self.loopVideo(videoPlayer: PlayerView)

	}
}

