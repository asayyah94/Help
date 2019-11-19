//
//  ViewController.swift
//  help
//
//  Created by Amirhossein Sayyah on 4/12/18.
//  Copyright © 2018 Amirhossein Sayyah. All rights reserved.
//

import UIKit
import Alamofire
import AlamofireSwiftyJSON
import SwiftyJSON
import McPicker
import GooglePlaces
import CoreLocation
import EasyToast
import SwiftSpinner

class ViewController: UIViewController, CLLocationManagerDelegate, UITableViewDataSource, UITableViewDelegate {
    
    var selectedRowNumber: Int = 0
    @IBOutlet weak var myTableView: UITableView!
    
    //////when a table row is selected
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        selectedRowNumber = indexPath.row
        
        self.performSegue(withIdentifier: "detailsFromFavs", sender: self)
        
    }
    
    //////prepare before doing a segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?){
        if segue.identifier == "detailsFromFavs"{
            var vc = segue.destination as! DetailsViewController
            vc.result = favs[selectedRowNumber]
        }else{
            var vc = segue.destination as! ResultsViewController
            vc.params = params
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return favs.count
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == UITableViewCellEditingStyle.delete) {
            // handle delete (by removing the data from your array and updating the tableview)
            var result = favs[indexPath.row]
            removeFromFavs(place_id: "\(result["place_id"])")
            myTableView.deleteRows(at: [indexPath], with: .fade)
            if favs.count == 0 {
                favView.isHidden = true
                emptyFavView.isHidden = false
            }
            self.view.showToast("\(result["name"])" + " was removed from favorites", position: .bottom, popTime: 3, dismissOnTap: true)
        }
    }
    
    //////fill the table with fav data
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FavsTableViewCell", for: indexPath) as! FavsTableViewCell
        let thisLabel = favs[indexPath.row]
        cell.nameLabel.text = "\(thisLabel["name"])"
        cell.addressLabel.text = "\(thisLabel["vicinity"])"
        cell.isFav = true
        
        cell.result = thisLabel
        
        Alamofire.request("\(thisLabel["icon"])").responseImage { response in
            debugPrint(response)
            if let image = response.result.value {
                
                cell.imageShow.image = image
            }
        }
        
        return cell
    }
    
    let locationManager = CLLocationManager()
    
    @IBOutlet weak var formView: UIView!
    @IBOutlet weak var favView: UIView!
    @IBOutlet weak var emptyFavView: UIView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    @IBAction func indexChanged() {
        switch segmentedControl.selectedSegmentIndex
        {
            case 0:
                favView.isHidden = true
                emptyFavView.isHidden = true
                formView.isHidden = false
            case 1:
                formView.isHidden = true
                if favs.count == 0 {
                    favView.isHidden = true
                    emptyFavView.isHidden = false
                }else{
                    emptyFavView.isHidden = true
                    favView.isHidden = false
                    myTableView.reloadData()
                }
            default:
                break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            hereLat = Float(location.coordinate.latitude)
            hereLon = Float(location.coordinate.longitude)
        }
    }
    
    var hereLon: Float = 0
    var hereLat: Float = 0
    var thereLon: Float = 0
    var thereLat: Float = 0
    var keyword: String = ""
    var distance: String = "16090"
    var category: String = "Default"
    var from: String = "here"
    var results: [JSON] = []
    
    @IBOutlet weak var categoryTextField: McTextField!
    @IBOutlet weak var fromTextField: UITextField!
    @IBOutlet weak var keywordTextField: UITextField!
    @IBOutlet weak var distanceTextField: UITextField!
    
    // Present the Autocomplete view controller when the button is pressed.
    @IBAction func autocompleteClicked(_ sender: UITextField) {
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.delegate = self
        present(autocompleteController, animated: true, completion: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        switch segmentedControl.selectedSegmentIndex
        {
            case 1:
                formView.isHidden = true
                if favs.count == 0 {
                    favView.isHidden = true
                    emptyFavView.isHidden = false
                }else{
                    emptyFavView.isHidden = true
                    favView.isHidden = false
                    myTableView.reloadData()
                }
            default:
                break
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        distanceTextField.keyboardType = .numberPad
        
        //////load saved favs
        let userDefaults = UserDefaults.standard
        if userDefaults.array(forKey: "myArray") != nil{
            favs = [JSON]()
            var myArray: [[String:String]] = userDefaults.array(forKey: "myArray") as! [[String : String]]
            userDefaults.set(nil, forKey: "myArray")
            for dict in myArray{
                var thisJson: JSON = ["place_id": dict["place_id"]!, "name": dict["name"]!, "vicinity": dict["vicinity"]!, "icon": dict["icon"]!]
                favs.append(thisJson)
            }
        }
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

        favView.isHidden = true
        emptyFavView.isHidden = true
        formView.isHidden = false
        
        myTableView.delegate = self
        myTableView.dataSource = self
        
        locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest // You can change the locaiton accuary here.
            locationManager.startUpdatingLocation()
        }
        
        let data: [[String]] = [["Default","Airport","Amusement Park","Aquarium","Art Gallery","Bakery","Bar","Beauty Salon","Bowling Alley","Bus Station","Cafe","Campground","Car Rental","Casino","Lodging","Movie Theater","Museum","Night Club","Park","Parking","Restaurant","Shopping Mall","Stadium","Subway Station","Taxi Stand","Train Station","Transit Station","Travel Agency","Zoo"]]
        let mcInputView = McPicker(data: data)
        categoryTextField.inputViewMcPicker = mcInputView
        categoryTextField?.text = category
        categoryTextField.doneHandler = { [weak categoryTextField] (selections) in
            categoryTextField?.text = selections[0]!
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    var params: [String:String] = [:]
    
    @IBAction func search(){
        if keywordTextField?.text == "" {
            self.view.showToast("Keyword cannot be empty", position: .bottom, popTime: 3, dismissOnTap: true)
        }else{
            keyword = (keywordTextField.text?.lowercased())!
            keyword = keyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
            if distanceTextField?.text != "" {
                distance = String(Float((distanceTextField.text)!)! * 1609)
            }
            category = (categoryTextField.text)!
            category = category.replacingOccurrences(of: " ", with: "_").lowercased()
            
            var latlon = ""
            if from == "here"{
                latlon = "\(hereLat)" + "+" + "\(hereLon)"
            } else {
                latlon = "\(thereLat)" + "+" + "\(thereLon)"
            }
            //do the get request here
            params = ["latlon": latlon, "distance": distance, "category":category, "keyword": keyword]
            self.performSegue(withIdentifier: "search", sender: self)
        }
    }
    
    
    @IBAction func clear(){
        keyword = ""
        distance = "16090"
        category = "Default"
        from = "here"
        keywordTextField?.text = ""
        categoryTextField?.text = "Default"
        distanceTextField?.text = ""
        fromTextField.text = "Your location"   
    }
    

}

//////use google api to autocoplete the address
extension ViewController: GMSAutocompleteViewControllerDelegate {
    
    // Handle the user's selection.
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        dismiss(animated: true, completion: nil)
        fromTextField.text = place.formattedAddress
        var coord = place.coordinate
        from = "there"
        thereLat = Float(coord.latitude)
        thereLon = Float(coord.longitude)
        
    }
    
    func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
        // TODO: handle the error.
        print("Error: ", error.localizedDescription)
    }
    
    // User canceled the operation.
    func wasCancelled(_ viewController: GMSAutocompleteViewController) {
        dismiss(animated: true, completion: nil)
    }
    
    // Turn the network activity indicator on and off again.
    func didRequestAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    func didUpdateAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    
}

