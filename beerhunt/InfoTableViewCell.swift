//
//  IntoTableViewCell.swift
//  beerhunt
//
//  Created by ShimmenNobuyoshi on 2017/09/13.
//  Copyright © 2017年 ShimmenNobuyoshi. All rights reserved.
//

import UIKit

class InfoTableViewCell: UITableViewCell {
    
    @IBOutlet weak var infoImageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
}
