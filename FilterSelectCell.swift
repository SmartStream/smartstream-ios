//
//  FilterSelectCell.swift
//  SmartStream
//
//  Created by Jerry on 3/7/16.
//  Copyright © 2016 SmartStream. All rights reserved.
//

import UIKit

class FilterSelectCell: UITableViewCell {

    @IBOutlet var filterLabel: UILabel!
    @IBOutlet var filterCheckImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        backgroundColor = UIColor.clearColor()
        filterLabel.font = Theme.Fonts.LightNormalTypeFace.font
        filterLabel.textColor = Theme.Colors.HighlightColor.color
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
