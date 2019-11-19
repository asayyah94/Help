//
//  ReviewsTableViewCell.swift
//  help
//
//  Created by Amirhossein Sayyah on 4/18/18.
//  Copyright © 2018 Amirhossein Sayyah. All rights reserved.
//

import UIKit
import Cosmos

class ReviewsTableViewCell: UITableViewCell {
    
    
    @IBOutlet weak var myImage: UIImageView!
    @IBOutlet weak var myName: UILabel!
    @IBOutlet weak var myDate: UILabel!
    @IBOutlet weak var myText: UITextView!
    @IBOutlet weak var myRating: CosmosView!
    
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
