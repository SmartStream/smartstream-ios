//
//  FilterSwitchCell.swift
//  SmartStream
//
//  Created by Jerry on 3/6/16.
//  Copyright © 2016 SmartStream. All rights reserved.
//

import UIKit

class FilterSwitchCell: UITableViewCell {

    @IBOutlet var filterLabel: UILabel!
    @IBOutlet var filterSwitch: UISwitch!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
