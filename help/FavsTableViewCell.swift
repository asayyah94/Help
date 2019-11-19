//
//  FavsTableViewCell.swift
//  help
//
//  Created by Amirhossein Sayyah on 4/14/18.
//  Copyright © 2018 Amirhossein Sayyah. All rights reserved.
//

import UIKit
import SwiftyJSON

class FavsTableViewCell: UITableViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var imageShow: UIImageView!
    
    var isFav: Bool = false
    var result: JSON!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
