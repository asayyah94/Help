//
//  DetailsViewController.swift
//  help
//
//  Created by Amirhossein Sayyah on 4/16/18.
//  Copyright © 2018 Amirhossein Sayyah. All rights reserved.
//

import UIKit
import Alamofire
import AlamofireSwiftyJSON
import SwiftyJSON
import McPicker
import GooglePlaces
import GoogleMaps
import CoreLocation
import EasyToast
import SwiftSpinner
import Cosmos

class DetailsViewController: UIViewController, UITabBarDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UITableViewDataSource, UITableViewDelegate, GMSMapViewDelegate {
    
    @IBOutlet weak var sortingSegmentedControl: UISegmentedControl!
    @IBOutlet weak var orderSegmentedControl: UISegmentedControl!
    @IBOutlet weak var TravelModeSegmentedControl: UISegmentedControl!
    @IBOutlet weak var whichReviewSegmentedControl: UISegmentedControl!
    
    @IBOutlet weak var fromTextField: UITextField!
    
    @IBOutlet weak var infoTabRatingCosmosView: CosmosView!
    
    @IBOutlet weak var actualMapView: GMSMapView!
    
    var destinationMarker = GMSMarker()
    var polyline: GMSPolyline!
    
    var id: String = ""
    
    var hereLat: Float = 0
    var hereLon: Float = 0
    
    var thereLat: Float = 0
    var thereLon: Float = 0
    
    func drawPath(mode: String){
        var origin = "\(hereLat),\(hereLon)"
        var destination = "\(thereLat),\(thereLon)"
        var url = "https://maps.googleapis.com/maps/api/directions/json?origin=" + origin + "&destination=" + destination + "&mode=" + mode
        if polyline != nil{
            polyline.map = nil
        }
        Alamofire.request(url).responseSwiftyJSON {
                response in
                var json = response.result.value //A JSON object
                var isSuccess = response.result.isSuccess
                if (isSuccess && (json != nil)) {
                    //use json here ///////////////
                    var routes = json!["routes"].array!
                    if routes != [] {
                        var route = routes[0]
                        let routeOverviewPolyline = route["overview_polyline"].dictionary
                        let points = routeOverviewPolyline!["points"]?.stringValue
                        let path = GMSPath(fromEncodedPath: points!)
                        self.polyline = GMSPolyline(path: path)
                        self.polyline.strokeWidth = 3
                        self.polyline.strokeColor = UIColor.purple
                        self.polyline.map = self.actualMapView
                        var bounds = GMSCoordinateBounds()
                        for index in 1...path!.count() {
                            bounds = bounds.includingCoordinate(path!.coordinate(at: index))
                        }
                        self.actualMapView.animate(with: GMSCameraUpdate.fit(bounds))
                    }else{
                        self.view.showToast("No path found!", position: .bottom, popTime: 3, dismissOnTap: true)
                    }
                    
                }else{
                    self.view.showToast("Something went wrong. Please try again.", position: .bottom, popTime: 3, dismissOnTap: true)
                }
                
        }
        
    }
    
    @IBAction func autocompleteClicked(_ sender: UITextField) {
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.delegate = self
        present(autocompleteController, animated: true, completion: nil)
    }
    
    @IBAction func travelIndexChanged(){
        if fromTextField.text != ""{
            destinationMarker.position = CLLocationCoordinate2D(latitude: CLLocationDegrees(hereLat), longitude: CLLocationDegrees(hereLon))
            destinationMarker.map = actualMapView
            switch TravelModeSegmentedControl.selectedSegmentIndex
            {
                case 0: drawPath(mode: "driving")
                case 1: drawPath(mode: "bicycling")
                case 2: drawPath(mode: "transit")
                case 3: drawPath(mode: "walking")
                default:
                    break
            }
        }else{
            self.view.showToast("From field cannot be empty!", position: .bottom, popTime: 3, dismissOnTap: true)
        }
    }
    
    @IBOutlet weak var myTable: UITableView!
    
    var reviewResults: [[String:String]] = []
    
    var yelpReviewResults: [[String:String]] = []
    
    func setReviewResults(){
        reviewResults = []
        var reviews = completeResult!["reviews"].array
        if reviews == nil{
            return
        }
        for review in reviews!{
            var name = "\(review["author_name"])"
            var rating = "\(review["rating"])"
            var text = "\(review["text"])"
            var photoURL = "\(review["profile_photo_url"])"
            var time = "\(review["time"])"
            var url = "\(review["author_url"])"
            
            let date = NSDate(timeIntervalSince1970: (Double("\(review["time"])") as! Double))
            
            let dayTimePeriodFormatter = DateFormatter()
            dayTimePeriodFormatter.dateFormat = "YYYY-MM-dd hh:mm:ss"
            
            let dateString = dayTimePeriodFormatter.string(from: date as Date)
            reviewResults.append(["name":name, "rating":rating, "text":text, "photoURL": photoURL, "date":dateString, "time": time, "url": url])
            
        }
        myTable.reloadData()
    }
    
    
    @IBAction func whichReviewIndexChanged(){
        if whichReviewSegmentedControl.selectedSegmentIndex == 0{
            if completeResult!["reviews"].array == nil {
                noReviewsView.isHidden = false
            }
            else{
                noReviewsView.isHidden = true
            }
        }else{
            if jsonYelpReviews == [] {
                noReviewsView.isHidden = false
            }
            else{
                noReviewsView.isHidden = true
            }
        }
        myTable.reloadData()
    }
    func setYelpReviewResults(){
        yelpReviewResults = []
        
        if jsonYelpReviews == []{
            return
        }
        for review in jsonYelpReviews{
            var name = "\(review["user"]["name"])"
            var rating = "\(review["rating"])"
            var text = "\(review["text"])"
            var photoURL = "\(review["user"]["image_url"])"
            var time = "\(review["time_created"])"
            var url = "\(review["url"])"
            
            
            yelpReviewResults.append(["name":name, "rating":rating, "text":text, "photoURL": photoURL, "date":time, "time": time, "url": url])
            
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if whichReviewSegmentedControl.selectedSegmentIndex == 0 {
            return reviewResults.count
        }else{
            return yelpReviewResults.count
        }
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        var thisURL: String = ""
        if whichReviewSegmentedControl.selectedSegmentIndex == 0 {
            thisURL = reviewResults[indexPath.row]["url"]!
        }else{
            thisURL = yelpReviewResults[indexPath.row]["url"]!
        }
        
        var url = URL(string: thisURL)
        
        UIApplication.shared.open(url!, options: [:])
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ReviewsTableViewCell", for: indexPath) as! ReviewsTableViewCell
        var thisReview: [String:String] = [:]
        if whichReviewSegmentedControl.selectedSegmentIndex == 0 {
            thisReview = reviewResults[indexPath.row]
        }else{
            thisReview = yelpReviewResults[indexPath.row]
        }
        cell.myRating.rating = Double(thisReview["rating"]!)!
        cell.myText.text = thisReview["text"]
        cell.myDate.text = thisReview["date"]
        cell.myName.text = thisReview["name"]
        
        Alamofire.request(thisReview["photoURL"]!).responseImage { response in
            debugPrint(response)
            if let image = response.result.value {
                cell.myImage.image = image
            }else{
                cell.myImage.image = #imageLiteral(resourceName: "emptyPhotoURL")
            }
        }
        
        return cell
    }
    
    
    var photosArray:[UIImage] = []
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photosArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotosCollectionViewCell", for: indexPath) as! PhotosCollectionViewCell
        cell.imageView.image = photosArray[indexPath.row]
        return cell
    }
    
    func loadPhotosForPlace(placeID: String) {
        GMSPlacesClient.shared().lookUpPhotos(forPlaceID: placeID) { (photos, error) -> Void in
            if let error = error {
                // TODO: handle the error.
                print("Error: \(error.localizedDescription)")
            } else {
                var myPhotos = photos?.results
                for photo in myPhotos!{
                    self.loadImageForMetadata(photoMetadata: photo)
                }
            }
        }
    }

    func loadImageForMetadata(photoMetadata: GMSPlacePhotoMetadata) {
        GMSPlacesClient.shared().loadPlacePhoto(photoMetadata, callback: {
            (photo, error) -> Void in
            if let error = error {
                // TODO: handle the error.
                print("Error: \(error.localizedDescription)")
            } else {
                self.photosArray.append(photo!)
            }
        })
    }
    
    
    @IBOutlet weak var tabBar: UITabBar!
    @IBOutlet weak var infoView: UIView!
    @IBOutlet weak var photosView: UIView!
    @IBOutlet weak var mapView: UIView!
    @IBOutlet weak var reviewsView: UIView!
    @IBOutlet weak var noReviewsView: UIView!

    
    @IBOutlet weak var addressTextView: UITextView!
    @IBOutlet weak var googlePageTextView: UITextView!
    @IBOutlet weak var phoneNumberTextView: UITextView!
    @IBOutlet weak var priceLevelTextView: UITextView!
    @IBOutlet weak var websiteTextView: UITextView!
    
    
    var favBarButtonItem: UIBarButtonItem!
    var tweetBarButtonItem: UIBarButtonItem!
    
    @IBOutlet weak var myCollectionView: UICollectionView!
    
    var result: JSON!
    var completeResult: JSON!
    
    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        if item == tabBar.items![0]{
            infoView.isHidden = false
            mapView.isHidden = true
            photosView.isHidden = true
            reviewsView.isHidden = true
            noReviewsView.isHidden = true
        }else if item == tabBar.items![1]{
            myCollectionView.reloadData()
            mapView.isHidden = true
            infoView.isHidden = true
            photosView.isHidden = false
            reviewsView.isHidden = true
            noReviewsView.isHidden = true
        }else if item == tabBar.items![2]{
            infoView.isHidden = true
            photosView.isHidden = true
            reviewsView.isHidden = true
            noReviewsView.isHidden = true
            mapView.isHidden = false
            
            // Create a GMSCameraPosition that tells the map to display the
            // coordinate -33.86,151.20 at zoom level 6.
            let camera = GMSCameraPosition.camera(withLatitude: CLLocationDegrees(thereLat), longitude: CLLocationDegrees(thereLon), zoom: 14)
            actualMapView.camera = camera
            
            let marker = GMSMarker()
            marker.position = camera.target
            marker.map = actualMapView
            
        }else if item == tabBar.items![3]{
            mapView.isHidden = true
            infoView.isHidden = true
            photosView.isHidden = true
            reviewsView.isHidden = false
            if whichReviewSegmentedControl.selectedSegmentIndex == 0{
                if completeResult!["reviews"].array == nil{
                    noReviewsView.isHidden = false
                }
            }else{
                if jsonYelpReviews == []{
                    noReviewsView.isHidden = false
                }
            }
            
        }
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        //get detailed result and save it to result
        //cosmosView.settings.updateOnTouch = false
        
        myCollectionView.delegate = self
        myCollectionView.dataSource = self
        
        myTable.delegate = self
        myTable.dataSource = self
        
        
        
        actualMapView.delegate = self
        
        
        loadPhotosForPlace(placeID: "\(result["place_id"])")
        tabBar.delegate = self
        infoView.isHidden = false
        photosView.isHidden = true
        reviewsView.isHidden = true
        noReviewsView.isHidden = true
        mapView.isHidden = true
        tabBar.selectedItem = tabBar.items![0]
        if isInFavs(place_id: "\(result["place_id"])"){
            favBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "favorite-filled"), style: .plain, target: self, action: #selector(favTapped))
        }else{
            favBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "favorite-empty"), style: .plain, target: self, action: #selector(favTapped))
        }
        tweetBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "forward-arrow"), style: .plain, target: self, action: #selector(tweetTapped))
        self.navigationItem.title = "\(result["name"])"
        self.navigationItem.setRightBarButtonItems([favBarButtonItem,tweetBarButtonItem], animated: true)
        requestData()
        // Do any additional setup after loading the view.
    }
    
    var jsonYelpReviews: [JSON] = []
    
    func requestYelpReviews(){
        Alamofire.request(
            URL(string: "http://asayyah.us-east-2.elasticbeanstalk.com/place.php")!,
            method: .get,
            parameters: ["yelp": "reviews", "id": id]).responseSwiftyJSON {
                response in
                var json = response.result.value //A JSON object
                var isSuccess = response.result.isSuccess
                if (isSuccess && (json != nil)) {
                    //use json here ///////////////
                    self.jsonYelpReviews = json!["reviews"].array!
                    
                    self.setYelpReviewResults()
                }else{
                    self.view.showToast("Something went wrong. Please try again.", position: .bottom, popTime: 3, dismissOnTap: true)
                }
        }
    }

    func requestYelpData(){
        Alamofire.request(
            URL(string: "http://asayyah.us-east-2.elasticbeanstalk.com/place.php")!,
            method: .get,
            parameters: ["yelp": "businesses", "lat": String(thereLat), "lon": String(thereLon), "term": ("\(self.result["name"])").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!]).responseSwiftyJSON {
                response in
                var json = response.result.value //A JSON object
                var isSuccess = response.result.isSuccess
                if (isSuccess && (json != nil)) {
                    //use json here ///////////////
                    var businesses = json!["businesses"].array
                    if businesses  == [] {
                        self.view.showToast("Something went wrong. Please try again.", position: .bottom, popTime: 3, dismissOnTap: true)
                    }else{
                        
                        for business in businesses!{
                            
                            if "\(self.result["name"])" == "\(business["name"])"{
                                self.id = "\(business["id"])"
                                
                                self.requestYelpReviews()
                                break
                            }
                        }
                    }
                }else{
                    self.view.showToast("Something went wrong. Please try again.", position: .bottom, popTime: 3, dismissOnTap: true)
                }
        }
    }
    
    @IBOutlet weak var noRatingLabel: UILabel!
    
    func setInfoTab(){
        addressTextView.text = "\(completeResult["vicinity"])"
        googlePageTextView.text = "\(completeResult["url"])"
        if completeResult["international_phone_number"] != JSON.null{
            phoneNumberTextView.text = "\(completeResult["international_phone_number"])"
        }
        if completeResult["price_level"] != JSON.null{
            var thisPriceLevel = ""
            for i in 1...Int("\(completeResult["price_level"])")!{
                thisPriceLevel += "$"
            }
            priceLevelTextView.text = thisPriceLevel
        }
        if completeResult["website"] != JSON.null{
            websiteTextView.text = "\(completeResult["website"])"
        }else{
            websiteTextView.text = "\(completeResult["url"])"
        }
        if completeResult["rating"] != JSON.null{
            infoTabRatingCosmosView.isHidden = false
            noRatingLabel.isHidden = true
            infoTabRatingCosmosView.rating = Double("\(completeResult["rating"])")!
        }else{
            infoTabRatingCosmosView.isHidden = true
            noRatingLabel.isHidden = false
        }
        addressTextView.isScrollEnabled = false
        googlePageTextView.isScrollEnabled = false
        phoneNumberTextView.isScrollEnabled = false
        priceLevelTextView.isScrollEnabled = false
        websiteTextView.isScrollEnabled = false
        
        addressTextView.centerVertically()
        googlePageTextView.centerVertically()
        phoneNumberTextView.centerVertically()
        priceLevelTextView.centerVertically()
        websiteTextView.centerVertically()
    }
    
    @objc func tweetTapped(){
        var thisURL: String = ""
        if completeResult["website"] == JSON.null{
            thisURL = "\(completeResult["url"])"
        }else{
            thisURL = "\(completeResult["website"])"
        }
        var text = "https://twitter.com/intent/tweet?text=" + "Check out " + "\(result["name"])" + " located at " + "\(result["vicinity"])" + ". Website: " + thisURL + " #TravelAndEntertainmentSearch"
        var url = URL(string: text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)
        
        UIApplication.shared.open(url!, options: [:])
    }
    
    @objc func favTapped(){
        if isInFavs(place_id: "\(result["place_id"])"){
            favBarButtonItem.image = #imageLiteral(resourceName: "favorite-empty")
            removeFromFavs(place_id: "\(result["place_id"])")
            self.view.showToast("\(result["name"])" + " was removed from favorites", position: .bottom, popTime: 3, dismissOnTap: true)
        }else{
            favBarButtonItem.image = #imageLiteral(resourceName: "favorite-filled")
            addToFavs(thisFav: result)
            self.view.showToast("\(result["name"])" + " was added to favorites", position: .bottom, popTime: 3, dismissOnTap: true)
        }
    }
    
    func requestData(){
        SwiftSpinner.show("Loading Place's Details...")
        Alamofire.request(
            URL(string: "http://asayyah.us-east-2.elasticbeanstalk.com/place.php")!,
            method: .get,
            parameters: ["place_id": "\(result["place_id"])"]).responseSwiftyJSON {
                response in
                var json = response.result.value //A JSON object
                var isSuccess = response.result.isSuccess
                SwiftSpinner.hide()
                if (isSuccess && (json != nil)) {
                    //use json here ///////////////
                    self.completeResult = json!["result"]
                    self.thereLat = Float("\(self.completeResult["geometry"]["location"]["lat"])")!
                    self.thereLon = Float("\(self.completeResult["geometry"]["location"]["lng"])")!
                    self.requestYelpData()
                    if self.completeResult  == [] {
                        self.view.showToast("Something went wrong. Please try again.", position: .bottom, popTime: 3, dismissOnTap: true)
                    }else{
                        self.setInfoTab()
                        self.setReviewResults()
                    }
                }else{
                    self.view.showToast("Something went wrong. Please try again.", position: .bottom, popTime: 3, dismissOnTap: true)
                }
        }
        
    }
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func indexChanged() {
        switch sortingSegmentedControl.selectedSegmentIndex
        {
            case 0:
                setReviewResults()
                setYelpReviewResults()
                if orderSegmentedControl.selectedSegmentIndex == 1{
                    reviewResults = reviewResults.reversed()
                    yelpReviewResults = yelpReviewResults.reversed()
                }
                myTable.reloadData()
            case 1:
                if orderSegmentedControl.selectedSegmentIndex == 0{
                    reviewResults = reviewResults.sorted{$0["rating"]! < $1["rating"]!}
                    yelpReviewResults = yelpReviewResults.sorted{$0["rating"]! < $1["rating"]!}
                }else{
                    reviewResults = reviewResults.sorted{$0["rating"]! > $1["rating"]!}
                    yelpReviewResults = yelpReviewResults.sorted{$0["rating"]! > $1["rating"]!}
                }
                myTable.reloadData()
            case 2:
                if orderSegmentedControl.selectedSegmentIndex == 0{
                    reviewResults = reviewResults.sorted{$0["time"]! < $1["time"]!}
                    yelpReviewResults = yelpReviewResults.sorted{$0["time"]! < $1["time"]!}
                }else{
                    reviewResults = reviewResults.sorted{$0["time"]! > $1["time"]!}
                    yelpReviewResults = yelpReviewResults.sorted{$0["time"]! > $1["time"]!}
                }
                myTable.reloadData()
            default:
                break
        }
    }
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension UITextView {
    
    func centerVertically() {
        let fittingSize = CGSize(width: bounds.width, height: CGFloat.greatestFiniteMagnitude)
        let size = sizeThatFits(fittingSize)
        let topOffset = (bounds.size.height - size.height * zoomScale) / 2
        let positiveTopOffset = max(1, topOffset)
        contentOffset.y = -positiveTopOffset
    }
    
}

extension DetailsViewController: GMSAutocompleteViewControllerDelegate {
    
    // Handle the user's selection.
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        dismiss(animated: true, completion: nil)
        fromTextField.text = place.formattedAddress
        var coord = place.coordinate
        hereLat = Float(coord.latitude)
        hereLon = Float(coord.longitude)
        travelIndexChanged()
        
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
