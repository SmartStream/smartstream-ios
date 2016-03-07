//
//  FiltersViewController.swift
//  SmartStream
//
//  Created by Jerry on 3/5/16.
//  Copyright © 2016 SmartStream. All rights reserved.
//

import UIKit

class FiltersViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet var tableView: UITableView!
    
    private let filterCellID = "com.smartstream.FilterSwitchCell"
    private let filterSelectCellID = "com.smartstream.FilterSelectCell"
    private let filterData = ["Source" : ["YouTube", "Vimeo"], "Max Duration": ["Short < 1 min","Medium < 5 min","Long > 5 min"]]
    private var titles = []
    private var durationSelected = 2
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        titles = Array(filterData.keys)
        
        let filterCellNib = UINib(nibName: "FilterSwitchCell", bundle: NSBundle.mainBundle())
        tableView.registerNib(filterCellNib, forCellReuseIdentifier: filterCellID)
        
        let filterSelectCellNib = UINib(nibName: "FilterSelectCell", bundle: NSBundle.mainBundle())
        tableView.registerNib(filterSelectCellNib, forCellReuseIdentifier: filterSelectCellID)
        
        tableView.backgroundColor = Theme.Colors.BackgroundColor.color
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return titles[section] as? String
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return filterData["Source"]!.count
        case 1: return filterData["Max Duration"]!.count
        default: return 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCellWithIdentifier(filterCellID, forIndexPath: indexPath) as! FilterSwitchCell
            cell.filterLabel.text = filterData["Source"]![indexPath.row]
            cell.selectionStyle = UITableViewCellSelectionStyle.None
            return cell
        case 1:
            let cell = tableView.dequeueReusableCellWithIdentifier(filterSelectCellID, forIndexPath: indexPath) as! FilterSelectCell
            cell.filterCheckImageView.hidden = true
            cell.filterCheckImageView.alpha = 0
            if durationSelected == indexPath.row {
                UIView.animateWithDuration(1, animations: { () -> Void in
                    cell.filterCheckImageView.hidden = false
                    cell.filterCheckImageView.alpha = 1
                })
            }
            cell.filterLabel.text = filterData["Max Duration"]![indexPath.row]
            cell.selectionStyle = UITableViewCellSelectionStyle.None
            return cell
        default:
            let cell = tableView.dequeueReusableCellWithIdentifier(filterCellID, forIndexPath: indexPath) as! FilterSwitchCell
            cell.selectionStyle = UITableViewCellSelectionStyle.None
            return cell
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 1 {
            durationSelected = indexPath.row
            tableView.reloadData()
        }
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }
    
    func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header = view as! UITableViewHeaderFooterView
        header.contentView.backgroundColor = Theme.Colors.DarkBackgroundColor.color
        header.textLabel?.font = Theme.Fonts.NormalTypeFace.font
        header.textLabel?.textColor = Theme.Colors.HighlightColor.color
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
