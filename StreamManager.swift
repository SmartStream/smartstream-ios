//
//  StreamManager.swift
//  SmartStream
//
//  Created by Hieu Nguyen on 3/5/16.
//  Copyright © 2016 SmartStream. All rights reserved.
//

import UIKit
import AVFoundation
import SwiftPriorityQueue
import youtube_ios_player_helper

class StreamManager: NSObject {
    let ItemDidEndNotification = "com.smartu.streammanager.itemDidEnd"
    let ItemDidEndKey = "com.smartu.streammanager.itemDidEndKey"
    
    let youtubePlayerVars : [NSObject : AnyObject] = [
        "playsinline": 1 ,
        "controls": 0,
        "enablejsapi": 1,
        "autohide": 1,
        "autoplay" : 0,
        "modestbranding" : 1
    ]
    let myContext = UnsafeMutablePointer<()>()
    
    var nativePlayer: AVQueuePlayer?
    var nativePlayerLayer: AVPlayerLayer?
    var nativePlayerView: UIView?
    var youtubePlayerView: YTPlayerView?
    var webView: UIView?
    
    var priorityQueue: PriorityQueue<StreamItem>?
    var currItem: StreamItem?
    var timeObserver: AnyObject?
    
    var playerContainerView: UIView? {
        didSet {
            if playerContainerView == nil {return}
            nativePlayerView = UIView(frame: playerContainerView!.bounds)
            nativePlayerView!.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
            nativePlayerLayer!.frame = nativePlayerView!.bounds
            nativePlayerView!.layer.addSublayer(nativePlayerLayer!)
            playerContainerView!.addSubview(nativePlayerView!)
            
            youtubePlayerView = YTPlayerView(frame: playerContainerView!.bounds)
            youtubePlayerView!.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
            youtubePlayerView!.delegate = self
            playerContainerView!.addSubview(youtubePlayerView!)
        }
    }
    
    var stream: Stream? {
        didSet {
            if stream == nil || stream!.items.count == 0 {return}
            priorityQueue = PriorityQueue(ascending: true, startingValues: stream!.items)
            
            // Autoplay
            playNextItem()
        }
    }
    
    func playYoutubeItem(item: StreamItem!) {
        print("[MANAGER] play YoutubeItem")
        dispatch_async(dispatch_get_main_queue(),{
            self.youtubePlayerView?.loadWithVideoId(item.id!, playerVars: self.youtubePlayerVars)
        })
    }
    
    func playNativeItem(item: StreamItem!) {
        print("[MANAGER] play nativeItem")
        //        let currItem = nativePlayer?.currentItem
        //        nativePlayer?.insertItem(AVPlayerItem(URL: NSURL(string: item.url!)!), afterItem: currItem)
        //        nativePlayer?.advanceToNextItem()
        nativePlayer?.insertItem(AVPlayerItem(URL: NSURL(string: item.url!)!), afterItem: nil)
        nativePlayer?.play()
    }
    
    override init() {
        super.init()
        
        self.nativePlayer = AVQueuePlayer()
        self.nativePlayer!.addObserver(self, forKeyPath: "status", options: [.New], context: self.myContext)
        self.nativePlayer!.addObserver(self, forKeyPath: "duration", options: [.New], context: self.myContext)
        self.nativePlayer!.addObserver(self, forKeyPath: "loadedTimeRanges", options: [.New], context: self.myContext)
        self.nativePlayer!.addObserver(self, forKeyPath: "presentationSize", options: [.New], context: self.myContext)
        self.nativePlayer!.addObserver(self, forKeyPath: "error", options: [.New], context: self.myContext)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "nativePlayerDidFinishPlaying:", name: AVPlayerItemDidPlayToEndTimeNotification, object: nil)
        self.nativePlayerLayer = AVPlayerLayer(player: self.nativePlayer)
        self.nativePlayerLayer!.videoGravity = AVLayerVideoGravityResizeAspect
        
        NSNotificationCenter.defaultCenter().addObserverForName(ItemDidEndNotification, object: nil, queue: NSOperationQueue.mainQueue(), usingBlock: processItemEndEvent)
        
        // an observer for every second playback
        timeObserver = nativePlayer!.addPeriodicTimeObserverForInterval(CMTimeMake(1,1), queue: nil, usingBlock: { (time: CMTime) -> Void in
            if self.nativePlayer != nil && self.nativePlayer!.currentItem != nil {
                let currentSecond = self.nativePlayer!.currentItem!.currentTime().value / Int64(self.nativePlayer!.currentItem!.currentTime().timescale)
                let totalDuration = String(format: "%.2f", CMTimeGetSeconds(self.nativePlayer!.currentItem!.duration))
                print("[NATIVEPLAYER] progress: \(currentSecond) / \(totalDuration) secs")
            }
        })
    }
    
    deinit {
        stop()
        if timeObserver != nil {
            nativePlayer?.removeTimeObserver(timeObserver!)
        }
        self.nativePlayer?.removeObserver(self, forKeyPath: "status")
        self.nativePlayer?.removeObserver(self, forKeyPath: "duration")
        self.nativePlayer?.removeObserver(self, forKeyPath: "loadedTimeRanges")
        self.nativePlayer?.removeObserver(self, forKeyPath: "presentationSize")
        self.nativePlayer?.removeObserver(self, forKeyPath: "error")
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func playNextItem() {
        let item = priorityQueue!.pop()
        if item == nil {return}
        
        let extractor = item!.extractor
        print("[MANAGER] extractor = \(extractor!); id = \(item!.id!)")
        
        currItem = item
        if extractor == "youtube" {
            playerContainerView?.bringSubviewToFront(youtubePlayerView!)
            playYoutubeItem(item)
        } else {
            playerContainerView?.bringSubviewToFront(nativePlayerView!)
            playNativeItem(item)
        }
    }
    
    func play() {
        if currItem == nil {return}
        
        if currItem!.extractor == "youtube" {
            youtubePlayerView?.playVideo()
        } else {
            nativePlayer?.play()
        }
    }
    
    func stop() {
        nativePlayer?.pause()
        youtubePlayerView?.pauseVideo()
    }
    
    func next() {
        stop()
        playNextItem()
    }
    
    func notifyItemDidEnd() {
        NSNotificationCenter.defaultCenter().postNotificationName(ItemDidEndNotification, object: self, userInfo: nil)
    }
    
    func processItemEndEvent(notification: NSNotification) -> Void {
        print("[MANAGER] processItemEndEvent")
        playNextItem()
    }
    
}


// ==========================================================
// Option 1: Use native iOS player
// ==========================================================
extension StreamManager {
    
    func nativePlayerDidFinishPlaying(notification: NSNotification) {
        if nativePlayer?.rate != 0 && nativePlayer?.error == nil {
            notifyItemDidEnd()
        }
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if context != myContext {return}
        let nativePlayer = object as? AVPlayer
        if (nativePlayer == nil || nativePlayer != self.nativePlayer) {return}
        
        if keyPath == "status" {
            if nativePlayer!.status == AVPlayerStatus.ReadyToPlay {
                print("[NATIVEPLAYER] ready to play")
                
                let currentPlayerAsset = nativePlayer!.currentItem?.asset as? AVURLAsset
                if currentPlayerAsset != nil {
                    if currItem != nil && currItem!.url == currentPlayerAsset!.URL.absoluteString {
                        dispatch_async(dispatch_get_main_queue(),{
                            self.nativePlayerLayer?.layoutIfNeeded()
                            self.nativePlayer?.play()
                        })
                    }
                }
            } else if nativePlayer!.status == AVPlayerStatus.Failed {
                print("[NATIVEPLAYER] failed to play")
            } else {
                print("[NATIVEPLAYER] unhandled playerItem status \(nativePlayer!.status)")
            }
        } else if keyPath == "duration" {
            
        } else if keyPath == "loadedTimeRanges" {
            if let timeInterval = nativePlayer!.currentItem?.duration {
                let totalDuration = CMTimeGetSeconds(timeInterval)
                print("totalDuration = \(totalDuration)")
            }
        } else if keyPath == "presentationSize" {
            
        } else if keyPath == "error" {
            
        }
    }
    
}


// ==========================================================
// Option 2: Use youtube player
// ==========================================================
extension StreamManager: YTPlayerViewDelegate {
    
    func playerViewDidBecomeReady(playerView: YTPlayerView!) {
        print("[YOUTUBEPLAYER] playerViewDidBecomeReady")
        self.youtubePlayerView?.playVideo()
    }
    
    func playerView(playerView: YTPlayerView!, didChangeToState state: YTPlayerState) {
        print("[YOUTUBEPLAYER] didChangeToState \(state.rawValue)")
        if state == .Ended {
            print("[YOUTUBEPLAYER] video ended")
            notifyItemDidEnd()
        }
    }
    
    func playerView(playerView: YTPlayerView!, didChangeToQuality quality: YTPlaybackQuality) {
        print("[YOUTUBEPLAYER] didChangeToQuality \(quality.rawValue)")
    }
    
    func playerView(playerView: YTPlayerView!, didPlayTime playTime: Float) {
        let currentSecond = String(format: "%.2f", playTime)
        let totalDuration = String(format: "%.2f", playerView.duration())
        print("[YOUTUBEPLAYER] progress: \(currentSecond) / \(totalDuration) secs")
    }
    
    func playerView(playerView: YTPlayerView!, receivedError error: YTPlayerError) {
        print("[YOUTUBEPLAYER] didPlayTime \(error.rawValue)")
    }
    
    func playerViewPreferredWebViewBackgroundColor(playerView: YTPlayerView!) -> UIColor! {
        return UIColor.whiteColor()
    }
}


// ==========================================================
// Option 3: Use web view player
// ==========================================================
extension StreamManager {
    
}