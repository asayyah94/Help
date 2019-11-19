//
//  ResultsViewController.swift
//  help
//
//  Created by Amirhossein Sayyah on 4/13/18.
//  Copyright © 2018 Amirhossein Sayyah. All rights reserved.
//

import UIKit
import SwiftyJSON
import Alamofire
import AlamofireImage
import SwiftSpinner
import EasyToast


class ResultsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var myTableView: UITableView!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var prevButton: UIButton!
    var first: Bool = true
    
    var offset = 0
    
    var finishedRequest: Bool = false
    
    var next_page_token: String = ""
    
    var params: [String:String] = [:]
    
    var selectedRowNumber: Int = 0
    
    var thisPageNumber: Int = 0
    
    var numOfAllPages: Int = 0
    
    override func viewDidAppear(_ animated: Bool) {
        myTableView.reloadData()
    }
    
    @IBAction func goNext(){

        if (!finishedRequest && (numOfAllPages == thisPageNumber)){
            requestData()
        }else{
            goToNext()
        }
        
    }
    
    @IBAction func goPrev(){
        
        currentResults = Array(self.allResults[((thisPageNumber-2)*20)..<(thisPageNumber*20 - 20)])
        
        myTableView.reloadData()
        thisPageNumber -= 1
        checkPrevNextButton()
        
    }
    
    func checkPrevNextButton(){
        
        if thisPageNumber == 1{
            prevButton.isEnabled = false
        }else{
            prevButton.isEnabled = true
        }
        if (finishedRequest && (thisPageNumber == numOfAllPages)){
            nextButton.isEnabled = false
        }else{
            nextButton.isEnabled = true
        }
    }
    
    
    func goToNext(){
        
        if allResults.count <= (thisPageNumber+1) * 20 {
            self.currentResults = Array(self.allResults[(thisPageNumber*20)..<(allResults.count)])
        }else{
            self.currentResults = Array(self.allResults[(thisPageNumber*20)..<((thisPageNumber*20)+20)])
        }
        myTableView.reloadData()
        thisPageNumber += 1
        checkPrevNextButton()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        myTableView.delegate = self
        myTableView.dataSource = self
        
        resultsView.isHidden = true
        emptyResultsView.isHidden = true
        first = true
        requestData()
        
        // Do any additional setup after loading the view.
    }
    
    //////what to do if a row is selected
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        selectedRowNumber = indexPath.row
        var thisResult = currentResults[indexPath.row]
        //navigationItem.backBarButtonItem = UIBarButtonItem(title: "\(thisResult["name"])", style: .plain, target: nil, action: nil)
        self.performSegue(withIdentifier: "detailsFromResults", sender: self)
    }
    
    //////prepare for segue to go in details view controller
    override func prepare(for segue: UIStoryboardSegue, sender: Any?){
        var vc = segue.destination as! DetailsViewController
        vc.result = currentResults[selectedRowNumber]
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentResults.count
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "ResultsTableViewCell", for: indexPath) as! ResultsTableViewCell
        let thisLabel = currentResults[indexPath.row]
        cell.nameLabel.text = "\(thisLabel["name"])"
        cell.addressLabel.text = "\(thisLabel["vicinity"])"
        cell.isFav = false
    
        if isInFavs(place_id: "\(thisLabel["place_id"])"){
            cell.isFav = true
        }
        if cell.isFav{
            cell.favButton.setImage(UIImage(named: "favorite-filled")?.withRenderingMode(.alwaysTemplate), for: .normal)
            cell.favButton.tintColor = UIColor.red
            
        }else{
            cell.favButton.setImage(UIImage(named: "favorite-empty")?.withRenderingMode(.alwaysTemplate), for: .normal)
            cell.favButton.tintColor = UIColor.gray
        }
        cell.result = thisLabel
        
        Alamofire.request("\(thisLabel["icon"])").responseImage { response in
            debugPrint(response)
            if let image = response.result.value {
                cell.imageShow.image = image
            }
        }
        return cell
    }
    
    var allResults: [JSON] = []
    var currentResults: [JSON] = []
    
    
    @IBOutlet weak var resultsView: UIView!
    @IBOutlet weak var emptyResultsView: UIView!
    
    
    
    func requestData(){
        if first{
            first = false
            SwiftSpinner.show("Searching...")
            Alamofire.request(
                URL(string: "http://asayyah.us-east-2.elasticbeanstalk.com/place.php")!,
                method: .get,
                parameters: params).responseSwiftyJSON {
                    response in
                    var json = response.result.value //A JSON object
                    var isSuccess = response.result.isSuccess
                    
                    if (isSuccess && (json != nil)) {
                        //use json here ///////////////
                        if(json!["next_page_token"] != JSON.null){
                            self.finishedRequest = false
                            self.next_page_token = "\(json!["next_page_token"])"
                        }else{
                            self.finishedRequest = true
                        }
                        
                        self.currentResults = json!["results"].array!
                        self.allResults.append(contentsOf: self.currentResults)
                        self.numOfAllPages += 1
                        if self.currentResults  == [] {
                            self.resultsView.isHidden = true
                            self.emptyResultsView.isHidden = false
                        }else{
                            self.emptyResultsView.isHidden = true
                            self.resultsView.isHidden = false
                            self.goToNext()
                        }
                        SwiftSpinner.hide()
                    }else{
                        self.view.showToast("Something went wrong. Please try again.", position: .bottom, popTime: 3, dismissOnTap: true)
                        SwiftSpinner.hide()
                    }
                    
                    
            }
        }else{
            SwiftSpinner.show("Loading next page...")
            var isSuccess = false
            Alamofire.request(
                URL(string: "http://asayyah.us-east-2.elasticbeanstalk.com/place.php")!,
                method: .get,
                parameters: ["next_page_token":self.next_page_token]).responseSwiftyJSON {
                    response in
                    var json = response.result.value //A JSON object
                    isSuccess = response.result.isSuccess
                    if (isSuccess && (json != nil)) {
                        //use json here ///////////////
                        self.currentResults = json!["results"].array!
                        if self.currentResults != []{
                            if(json!["next_page_token"] != JSON.null){
                                self.finishedRequest = false
                                self.next_page_token = "\(json!["next_page_token"])"
                            }else{
                                self.finishedRequest = true
                            }
                            self.allResults.append(contentsOf: self.currentResults)
                            self.numOfAllPages += 1
                            self.goToNext()
                            
                        }
                        SwiftSpinner.hide()
                    }else{
                        SwiftSpinner.hide()
                        self.view.showToast("Something went wrong. Please try again.", position: .bottom, popTime: 3, dismissOnTap: true)
                    }
                    
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
