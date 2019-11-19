//
//  ResultsTableViewCell.swift
//  help
//
//  Created by Amirhossein Sayyah on 4/13/18.
//  Copyright © 2018 Amirhossein Sayyah. All rights reserved.
//

import UIKit
import SwiftyJSON
import EasyToast

class ResultsTableViewCell: UITableViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var imageShow: UIImageView!
    @IBOutlet weak var favButton: UIButton!
    var isFav: Bool = false
    var result: JSON!
    
    //////what to do if the heart is selected in results table
    @IBAction func addRemoveFav(){
        
        if isFav{
            isFav = false
            favButton.setImage(UIImage(named: "favorite-empty")?.withRenderingMode(.alwaysTemplate), for: .normal)
            favButton.tintColor = UIColor.gray
            removeFromFavs(place_id: "\(result["place_id"])")
            showToast("\(result["name"])" + " was removed from favorites", position: .bottom, popTime: 3, dismissOnTap: true)
        }else{
            isFav = true
            favButton.setImage(UIImage(named: "favorite-filled")?.withRenderingMode(.alwaysTemplate), for: .normal)
            favButton.tintColor = UIColor.red
            addToFavs(thisFav: result)
            showToast("\(result["name"])" + " was added to favorites", position: .bottom, popTime: 3, dismissOnTap: true)
        }
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
