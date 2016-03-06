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
    
    let youtubePlayerVars : [NSObject : AnyObject] = [ "playsinline": 1 , "autoplay" : 1 ]
    let myContext = UnsafeMutablePointer<()>()
    
    var currItem: StreamItem?
    var priorityQueue: PriorityQueue<StreamItem>?
    var stream: Stream? {
        didSet {
            if stream == nil || stream!.items.count == 0 {return}
            priorityQueue = PriorityQueue(ascending: true, startingValues: stream!.items)
            
            // Autoplay
            playNextItem()
        }
    }
    
    func playYoutubeItem(item: StreamItem!) {
        print("playYoutubeItem")
        dispatch_async(dispatch_get_main_queue(),{
            self.youtubePlayerView?.loadWithVideoId(item.id!, playerVars: self.youtubePlayerVars)
        })
    }
    
    func playNativeItem(item: StreamItem!) {
        print("playNativeItem")
        nativePlayer?.insertItem(AVPlayerItem(URL: NSURL(string: item.url!)!), afterItem: nil)
    }
    
    var nativePlayer: AVQueuePlayer?
    var nativePlayerLayer: AVPlayerLayer?
    var nativePlayerView: UIView?
    var youtubePlayerView: YTPlayerView?
    var webView: UIView?
    
    // Option 1: native player
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
    
    func setupAVPlayer() {
        self.nativePlayer = AVQueuePlayer()
        self.nativePlayer!.addObserver(self, forKeyPath: "status", options: [.New,.Old,.Initial], context: self.myContext)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "nativePlayerDidFinishPlaying:", name: AVPlayerItemDidPlayToEndTimeNotification, object: nil)
        self.nativePlayerLayer = AVPlayerLayer(player: self.nativePlayer)
        
        NSNotificationCenter.defaultCenter().addObserverForName(ItemDidEndNotification, object: nil, queue: NSOperationQueue.mainQueue(), usingBlock: processItemEndEvent)
    }
    
    override init() {
        super.init()
        setupAVPlayer()
    }
    
    deinit {
        self.nativePlayer?.pause()
        self.nativePlayer?.removeObserver(self, forKeyPath: "status")
    }
    
    func play() {
        if currItem == nil {return}
        
        if currItem!.extractor == "youtube" {
            playerContainerView?.bringSubviewToFront(youtubePlayerView!)
            youtubePlayerView?.playVideo()
        } else {
            playerContainerView?.bringSubviewToFront(nativePlayerView!)
            nativePlayer?.play()
        }
    }
    
    func stop() {
        nativePlayer?.pause()
        youtubePlayerView?.stopVideo()
    }
    
    func next() {
        playNextItem()
    }
    
    func notifyItemDidEnd() {
        NSNotificationCenter.defaultCenter().postNotificationName(ItemDidEndNotification, object: self, userInfo: nil)
    }
    
    func processItemEndEvent(notification: NSNotification) -> Void {
        print("processItemEndEvent")
        playNextItem()
    }
    
    func playNextItem() {
        let item = priorityQueue!.pop()
        if item == nil {return}
        
        let extractor = item!.extractor
        print("extractor = \(extractor!); id = \(item!.id!)")
        
        currItem = item
        if extractor == "youtube" {
            playYoutubeItem(item)
        } else {
            playNativeItem(item)
        }
    }
}


// ==========================================================
// Option 1: Use native iOS player
// ==========================================================
extension StreamManager {
    
    func nativePlayerDidFinishPlaying(notification: NSNotification) {
        notifyItemDidEnd()
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if context != myContext {return}
        let nativePlayer = object as? AVPlayer
        if (nativePlayer == nil || nativePlayer != self.nativePlayer) {return}
        
        if keyPath == "status" {
            if nativePlayer!.status == AVPlayerStatus.ReadyToPlay {
                print("ready to play")
                nativePlayer?.play()
            } else if nativePlayer!.status == AVPlayerStatus.Failed {
                print("failed to play")
            } else {
                print("unhandled playerItem status \(nativePlayer!.status)")
            }
        }
    }
    
}


// ==========================================================
// Option 2: Use youtube player
// ==========================================================
extension StreamManager: YTPlayerViewDelegate {
    
    func playerViewDidBecomeReady(playerView: YTPlayerView!) {
        print("youtubePlayer: playerViewDidBecomeReady")
        self.youtubePlayerView?.playVideo()
    }
    
    func playerView(playerView: YTPlayerView!, didChangeToState state: YTPlayerState) {
        print("youtubePlayer: didChangeToState \(state.rawValue)")
        if state == .Ended {
            print("youtubePlayer: video ended")
            notifyItemDidEnd()
        }
    }
}


// ==========================================================
// Option 3: Use web view player
// ==========================================================
extension StreamManager {
    
}
