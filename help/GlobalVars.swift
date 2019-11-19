//
//  GlobalVars.swift
//  help
//
//  Created by Amirhossein Sayyah on 4/14/18.
//  Copyright © 2018 Amirhossein Sayyah. All rights reserved.
//

import Foundation
import SwiftyJSON
  
var favs = [JSON]()

func isInFavs(place_id: String) -> Bool{
    for fav in favs{
        if "\(fav["place_id"])" == place_id{
            return true
        }
    }
    return false
}

func addToFavs(thisFav: JSON){
    favs.append(thisFav)
}

func removeFromFavs(place_id: String){
    favs = favs.filter { "\($0["place_id"])" != place_id }
}

