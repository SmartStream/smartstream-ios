//
//  StreamEditorViewController.swift
//  SmartStream
//
//  Created by Jerry on 3/5/16.
//  Copyright © 2016 SmartStream. All rights reserved.
//

import UIKit

protocol StreamEditorDelegate: class {
    func didSetStreamKeywords(keywords:[String])
}

class StreamEditorViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet var searchWrapperView: UIView!
    @IBOutlet var searchTextField: UITextField!
    @IBOutlet var tableView: UITableView!
    
    private var keywords:[String] = []
    
    weak var delegate: StreamEditorDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        uiSetup()
    }
    
    func uiSetup() {
        searchWrapperView.backgroundColor = Theme.Colors.DarkBackgroundColor.color
        searchTextField.font = Theme.Fonts.TitleThinTypeFace.font
        searchTextField.textColor = Theme.Colors.HighlightColor.color
        searchTextField.attributedPlaceholder = NSAttributedString(string: "Create Stream", attributes: [NSForegroundColorAttributeName: Theme.Colors.HighlightLightColor.color])
        tableView.backgroundColor = Theme.Colors.BackgroundColor.color
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return keywords.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let longpressGesture = UILongPressGestureRecognizer(target: self, action: "onLongPress:")
        let cell = tableView.dequeueReusableCellWithIdentifier("StreamEditorCell", forIndexPath: indexPath)
        cell.textLabel?.text = keywords[indexPath.row]
        cell.textLabel?.font = Theme.Fonts.LightNormalTypeFace.font
        cell.textLabel?.textColor = Theme.Colors.HighlightColor.color
        cell.addGestureRecognizer(longpressGesture)
        cell.backgroundColor = UIColor.clearColor()
        cell.selectionStyle = UITableViewCellSelectionStyle.None
        return cell
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        searchTextField.resignFirstResponder()
    }
    
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return UITableViewCellEditingStyle.None
    }
    
    func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, shouldIndentWhileEditingRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }
    
    func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
        let moveItem = keywords[sourceIndexPath.row]
        keywords.removeAtIndex(sourceIndexPath.row)
        keywords.insert(moveItem, atIndex: destinationIndexPath.row)
        tableView.setEditing(false, animated: true)
    }
    
    func onLongPress(sender: UILongPressGestureRecognizer) {
        tableView.setEditing(true, animated: true)
    }
    
    @IBAction func onBackTapped(sender: AnyObject) {
        delegate?.didSetStreamKeywords(self.keywords)
        dismissViewControllerAnimated(true) { () -> Void in
        }
    }
    
    @IBAction func onKeywordTapped(sender: AnyObject) {
        if let keyword = searchTextField.text {
            if keyword != "" {
                keywords.insert(keyword, atIndex: 0)
                searchTextField.text = ""
                tableView.reloadData()
            }
        }
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
