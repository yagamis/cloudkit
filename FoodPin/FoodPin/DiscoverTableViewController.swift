//
//  DiscoverTableViewController.swift
//  FoodPin
//
//  Created by xiaobo on 15/11/22.
//  Copyright © 2015年 xiaobo. All rights reserved.
//

import UIKit
import CloudKit

class DiscoverTableViewController: UITableViewController {
    
    @IBOutlet var spinner: UIActivityIndicatorView!
    var restaurants:[CKRecord] = []
    
    var imageCache = NSCache()
    
    func getRecordFromCloud() {
        //刷新前清空记录
        restaurants.removeAll()
        tableView.reloadData()
        
        
        let container = CKContainer.defaultContainer()
        let pubDB = container.publicCloudDatabase
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "Restaurant", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        //创建查询操作
        let qo = CKQueryOperation(query: query)
        qo.desiredKeys = ["name"]
        qo.queuePriority = .VeryHigh
        qo.resultsLimit = 50
        qo.recordFetchedBlock = { (record:CKRecord!) -> Void in
            if let record = record {
                self.restaurants.append(record)
            }
        }
        
        qo.queryCompletionBlock = { (cursor: CKQueryCursor?, e: NSError?) -> Void in
            if  (e != nil) {
                print(e?.localizedDescription)
                return
            }
            
            print("从iCloud获取数据成功")
            NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                self.tableView.reloadData()
                self.spinner.stopAnimating()
                self.refreshControl?.endRefreshing()
            })
        }
        
        //执行查询
        pubDB.addOperation(qo)

    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        spinner.hidesWhenStopped = true
        spinner.center = view.center
        view.addSubview(spinner)
        spinner.startAnimating()

        getRecordFromCloud()
        
        refreshControl = UIRefreshControl()
        refreshControl?.backgroundColor = UIColor.whiteColor()
        refreshControl?.tintColor = UIColor.grayColor()
        refreshControl?.addTarget(self, action: "getRecordFromCloud", forControlEvents: .ValueChanged)

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return restaurants.count
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)

        let restaurant = restaurants[indexPath.row]
        cell.textLabel?.text = restaurant.objectForKey("name") as? String
        
        //设置默认图像
        cell.imageView?.image = UIImage(named: "photoalbum")
        
        //检查图像url是否有缓存
        if let imageURL = imageCache.objectForKey(restaurant.recordID) as? NSURL {
            print("从缓存中获取图像")
            cell.imageView?.image = UIImage(data: NSData(contentsOfURL: imageURL)!)
        } else {
            //后台下载图像
            let pubDB = CKContainer.defaultContainer().publicCloudDatabase
            let imgFRO = CKFetchRecordsOperation(recordIDs: [restaurant.recordID])
            imgFRO.desiredKeys = ["image"]
            imgFRO.queuePriority = .VeryHigh
            
            imgFRO.perRecordCompletionBlock = { (record: CKRecord?, recordID: CKRecordID?, error: NSError?) -> Void in
                if error != nil {
                    print(error?.localizedDescription)
                    return
                }
                
                if let record = record {
                    NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                        if let image = record.objectForKey("image") as? CKAsset {
                            cell.imageView?.image = UIImage(data: NSData(contentsOfURL: image.fileURL)!)
                            //缓存图像url
                            self.imageCache.setObject(image.fileURL, forKey: restaurant.recordID)
                        }
                    })
                }
            }
            
            pubDB.addOperation(imgFRO)
        }
        return cell
    }


    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
