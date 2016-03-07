//
//  ViewController.swift
//  SmartStream
//
//  Created by Hieu Nguyen on 2/29/16.
//  Copyright © 2016 SmartStream. All rights reserved.
//

import UIKit
import AVFoundation
import youtube_ios_player_helper

class PlayerViewController: UIViewController {

    @IBOutlet weak var playerView: UIView!
    @IBOutlet weak var loadingLabel: UILabel!
    
    var streamManager = StreamManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        loadingLabel.hidden = false
        streamManager.playerContainerView = self.playerView
        
        StreamClient.sharedInstance.getStream { (stream, error) -> () in
            if stream != nil {
                self.streamManager.stream = stream
            }
        }
    }
    
    @IBAction func onPlayTapped(sender: AnyObject) {
        self.streamManager.play()
    }
    
    @IBAction func onStopTapped(sender: AnyObject) {
        self.streamManager.pause()
    }
    
    @IBAction func onNextTapped(sender: AnyObject) {
        self.streamManager.next()
    }
    
    @IBAction func onDismiss(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
}

