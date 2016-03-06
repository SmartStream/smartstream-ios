//
//  MenuTableViewController.swift
//  SmartStream
//
//  Created by Marc Anderson on 3/5/16.
//  Copyright © 2016 SmartStream. All rights reserved.
//

import UIKit

class MenuTableViewController: UITableViewController {

    var containerViewController: HomeViewController!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 3
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)

        if indexPath.section == 0 {
            let myStreamsStoryboard = UIStoryboard(name: "MyStreams", bundle: nil)
            let myStreamsNC = myStreamsStoryboard.instantiateViewControllerWithIdentifier("MyStreamsNavigationController") as! UINavigationController
            let myStreamsVC = myStreamsNC.topViewController as! MyStreamsViewController
            myStreamsVC.containerViewController = containerViewController
            containerViewController.contentViewController = myStreamsNC
        } else if indexPath.section == 1 {
            let profileStoryboard = UIStoryboard(name: "Profile", bundle: nil)
            let profileVC = profileStoryboard.instantiateViewControllerWithIdentifier("ProfileViewController") as! ProfileViewController
            profileVC.containerViewController = containerViewController
            containerViewController.contentViewController = profileVC
        } else if indexPath.section == 2 {
            let settingsStoryboard = UIStoryboard(name: "Settings", bundle: nil)
            let settingsVC = settingsStoryboard.instantiateViewControllerWithIdentifier("SettingsViewController") as! SettingsViewController
            settingsVC.containerViewController = containerViewController
            containerViewController.contentViewController = settingsVC
        }
    }
}
