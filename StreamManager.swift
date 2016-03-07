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
    let ItemAboutToEndNotification = "com.smartu.streammanager.itemAboutToEnd"
    
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
    var youtubeWebviewLoaded = false
    var webView: UIView?
    
    var priorityQueue: PriorityQueue<StreamItem>?
    var currItem: StreamItem?
    var timeObserver: AnyObject?
    
    var playerContainerView: UIView? {
        didSet {
            if playerContainerView == nil {return}
            playerContainerView!.backgroundColor = UIColor.blackColor()
            
            nativePlayerView = UIView(frame: playerContainerView!.bounds)
            nativePlayerView!.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
            nativePlayerView!.backgroundColor = UIColor.blackColor()
            
            nativePlayerLayer = AVPlayerLayer(player: self.nativePlayer)
            nativePlayerLayer!.videoGravity = AVLayerVideoGravityResizeAspect
            // TODO : investigate why nativePlayerView!.bounds doesn't work
            nativePlayerLayer!.frame = UIScreen.mainScreen().bounds
            nativePlayerView!.layer.addSublayer(nativePlayerLayer!)
            nativePlayerLayer!.needsDisplayOnBoundsChange = true
            nativePlayerView!.layer.needsDisplayOnBoundsChange = true
            playerContainerView!.addSubview(nativePlayerView!)
            
            youtubePlayerView = YTPlayerView(frame: playerContainerView!.bounds)
            youtubePlayerView!.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
            youtubePlayerView!.backgroundColor = UIColor.blackColor()
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
    
    func playNextYoutubeItem(item: StreamItem!) {
        print("[MANAGER] play next YoutubeItem")
        if item == currItem {return}
        dispatch_async(dispatch_get_main_queue(),{
            self.currItem = item
            
            if !self.youtubeWebviewLoaded {
                self.youtubeWebviewLoaded = true
                self.youtubePlayerView?.loadWithVideoId(item.id!, playerVars: self.youtubePlayerVars)
            } else {
                //self.youtubePlayerView?.loadVideoById(item.id!, startSeconds: 0.0, suggestedQuality: .Default)
                //self.youtubePlayerView?.playVideo()
            }
            
        })
    }
    
    func playNextNativeItem(item: StreamItem!) {
        print("[MANAGER] play next nativeItem")
        if item == currItem {return}
        //        nativePlayer?.insertItem(AVPlayerItem(URL: NSURL(string: item.url!)!), afterItem: currItem)
        //        nativePlayer?.advanceToNextItem()
        dispatch_async(dispatch_get_main_queue(),{
            self.currItem = item
            //nativePlayer?.removeAllItems()
            self.nativePlayer?.insertItem(AVPlayerItem(URL: NSURL(string: item.url!)!), afterItem: nil)
            self.nativePlayer?.play()
        })
    }
    
    override init() {
        super.init()
        
        self.nativePlayer = AVQueuePlayer()
        self.nativePlayer!.addObserver(self, forKeyPath: "status", options: [.New], context: self.myContext)
        self.nativePlayer!.addObserver(self, forKeyPath: "currentItem", options: [.New], context: self.myContext)
        self.nativePlayer!.addObserver(self, forKeyPath: "duration", options: [.New], context: self.myContext)
        self.nativePlayer!.addObserver(self, forKeyPath: "loadedTimeRanges", options: [.New], context: self.myContext)
        self.nativePlayer!.addObserver(self, forKeyPath: "presentationSize", options: [.New], context: self.myContext)
        self.nativePlayer!.addObserver(self, forKeyPath: "error", options: [.New], context: self.myContext)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "nativePlayerDidFinishPlaying:", name: AVPlayerItemDidPlayToEndTimeNotification, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserverForName(ItemDidEndNotification, object: nil, queue: NSOperationQueue.mainQueue(), usingBlock: processItemEndEvent)
        NSNotificationCenter.defaultCenter().addObserverForName(ItemAboutToEndNotification, object: nil, queue: NSOperationQueue.mainQueue(), usingBlock: processItemAboutToEndEvent)
        
        // an observer for every second playback
        timeObserver = nativePlayer!.addPeriodicTimeObserverForInterval(CMTimeMake(1,1), queue: nil, usingBlock: { (time: CMTime) -> Void in
            if self.nativePlayer != nil && self.nativePlayer!.currentItem != nil {
                let currentSecond = self.nativePlayer!.currentItem!.currentTime().value / Int64(self.nativePlayer!.currentItem!.currentTime().timescale)
                let totalDuration = CMTimeGetSeconds(self.nativePlayer!.currentItem!.duration)
                let totalDurationStr = String(format: "%.2f", totalDuration)
                print("[NATIVEPLAYER] progress: \(currentSecond) / \(totalDurationStr) secs")
                
                if totalDuration == totalDuration && Int64(totalDuration) - currentSecond == 5 {
                    self.notifyItemAboutToEnd()
                }
            }
        })
    }
    
    deinit {
        stop()
        if timeObserver != nil {
            nativePlayer?.removeTimeObserver(timeObserver!)
        }
        self.nativePlayer?.removeObserver(self, forKeyPath: "status")
        self.nativePlayer?.removeObserver(self, forKeyPath: "currentItem")
        self.nativePlayer?.removeObserver(self, forKeyPath: "duration")
        self.nativePlayer?.removeObserver(self, forKeyPath: "loadedTimeRanges")
        self.nativePlayer?.removeObserver(self, forKeyPath: "presentationSize")
        self.nativePlayer?.removeObserver(self, forKeyPath: "error")
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // Pre-buffering to smoothen transition
    var currCueId: String! = ""
    func prepareNextItem() {
        let item = priorityQueue!.peek()
        if item == nil || currCueId == item!.id! {return}
        
        let extractor = item!.extractor
        print("[MANAGER] buffering: extractor = \(extractor!); id = \(item!.id!)")
        
        if extractor == "youtube" {
            youtubePlayerView?.cueVideoById(item!.id!, startSeconds: 0.0, suggestedQuality: .Default)
            NSTimer.scheduledTimerWithTimeInterval(2, target: self, selector: "prepareYoutubeVideo", userInfo: nil, repeats: false)
            currCueId = item!.id!
        } else {
            // native player buffering
        }
    }
    
    func prepareYoutubeVideo() {
        self.youtubePlayerView?.playVideo()
    }
    
    func playNextItem() {
        let item = priorityQueue!.pop()
        if item == nil {return}
        
        let extractor = item!.extractor
        print("[MANAGER] extractor = \(extractor!); id = \(item!.id!)")
        
        if extractor == "youtube" {
            nativePlayerView?.hidden = true
            youtubePlayerView?.hidden = false
            playerContainerView?.bringSubviewToFront(youtubePlayerView!)
            playNextYoutubeItem(item)
        } else {
            nativePlayerView?.hidden = false
            youtubePlayerView?.hidden = true
            playerContainerView?.bringSubviewToFront(nativePlayerView!)
            playNextNativeItem(item)
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
    
    func pause() {
        nativePlayer?.pause()
        youtubePlayerView?.pauseVideo()
    }
    
    func stop() {
        nativePlayer?.pause()
        nativePlayer?.replaceCurrentItemWithPlayerItem(nil)
        youtubePlayerView?.stopVideo()
    }
    
    func next() {
        stop()
        playNextItem()
    }
    
    func notifyItemAboutToEnd() {
        NSNotificationCenter.defaultCenter().postNotificationName(ItemAboutToEndNotification, object: self, userInfo: nil)
    }
    
    func notifyItemDidEnd() {
        NSNotificationCenter.defaultCenter().postNotificationName(ItemDidEndNotification, object: self, userInfo: nil)
    }
    
    func processItemAboutToEndEvent(notification: NSNotification) -> Void {
        print("[MANAGER] processItemAboutToEndEvent")
        prepareNextItem()
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
                
                if let currentPlayerAsset = nativePlayer!.currentItem?.asset as? AVURLAsset {
                    if currItem != nil && currItem!.url == currentPlayerAsset.URL.absoluteString {
                        dispatch_async(dispatch_get_main_queue(),{
                            if let videoTrack = nativePlayer!.currentItem!.asset.tracksWithMediaType(AVMediaTypeVideo).first {
                                print("naturalSize = \(videoTrack.naturalSize)")
                                //print("preferredTransform = \(videoTrack.preferredTransform)")
                            }
                            self.nativePlayer?.play()
                        })
                    }
                }
            } else if nativePlayer!.status == AVPlayerStatus.Failed {
                print("[NATIVEPLAYER] failed to play")
            } else {
                print("[NATIVEPLAYER] unhandled playerItem status \(nativePlayer!.status)")
            }
            
        } else if keyPath == "currentItem" {
            
        } else if keyPath == "duration" {
            
            if let timeInterval = nativePlayer!.currentItem?.duration {
                let totalDuration = CMTimeGetSeconds(timeInterval)
                print("totalDuration = \(totalDuration)")
            }
            
        } else if keyPath == "loadedTimeRanges" {
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
        let totalDuration = playerView.duration()
        let totalDurationStr = String(format: "%.2f", playerView.duration())
        print("[YOUTUBEPLAYER] progress: \(currentSecond) / \(totalDurationStr) secs")
        if Int(totalDuration) - Int(playTime) == 5 {
            notifyItemAboutToEnd()
        }
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