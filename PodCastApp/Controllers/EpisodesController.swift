//
//  EpisodesController.swift
//  PodCastApp
//
//  Created by mohamed zead on 10/7/18.
//  Copyright © 2018 zead. All rights reserved.
//

import Foundation
import UIKit
import FeedKit
class EpisodesController : UITableViewController{
    
    fileprivate let cellID = "cellId"
    var Episodes = [Episode]()
    var podCast : PodCast?{
        didSet{
            self.navigationItem.title = podCast?.trackName
            fetchEpisodes()
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpTableView()
        
    }
    
    
    struct Episode{
        let title : String
    }
    //MARK:- Networking
    fileprivate func fetchEpisodes(){
        guard var feedURLString = podCast?.feedUrl else{return}
        feedURLString = feedURLString.contains("https") ? feedURLString : feedURLString.replacingOccurrences(of: "http", with: "https") //replacing Http with Https
        guard let feedURL = URL(string: feedURLString)else {return}
        let feedParser = FeedParser(URL: feedURL)
        feedParser?.parseAsync(result: { (result) in
            switch result {
            case let .rss(feed):
                feed.items?.forEach({ (feedItem) in
                    let episod = Episode(title: feedItem.title!)
                    self.Episodes.append(episod)
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                })
                break
            case .failure(_):
                break
            default :
                print("result is sometype ...")
            }
        })
    }
    
    //MARK:- tableView Methods
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Episodes.count
    }
    
    
    fileprivate func setUpTableView(){
        tableView.tableFooterView = UIView() //eliminates separator lines in tableView
        tableView.register(UITableViewCell.self, forCellReuseIdentifier:cellID)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellID) else{
            return UITableViewCell()}
        cell.textLabel?.text = Episodes[indexPath.row].title
        return cell
    }
    
    
}
