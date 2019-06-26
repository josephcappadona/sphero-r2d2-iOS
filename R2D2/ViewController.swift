//
//  ViewController.swift
//  R2D2
//
//  Created by Joseph Cappadona on 5/16/19.
//  Copyright © 2019 Joseph Cappadona. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController {
    
    var appDelegate: AppDelegate?
    
    let cellReuseIdentifier = "AvailableConnectionCell"
    @IBOutlet weak var availableConnectionsTableView: UITableView!
    @IBOutlet weak var discoveryButton: UIButton!
    
    var discoveredDescriptors: Set<ToyDescriptor> = Set<ToyDescriptor>()
    var discoveredDescriptorsByRSSI: [ToyDescriptor] = []
    var descriptorToRSSI: [ToyDescriptor : Int] = [:]
    var isDiscovering = false
    
    var toyBox: ToyBox? = nil
    var connectedToy: Toy? = nil
    var connectedAnyToy: AnyToy? = nil
    var connectedToyDescriptor: ToyDescriptor? = nil
    var readyingToyDescriptor: ToyDescriptor? = nil
    var roller: RobotKeepAlive? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        appDelegate = UIApplication.shared.delegate as? AppDelegate
        toyBox = appDelegate?.globalToyBox
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupToybox()
        resetConnectedToyObjects()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        toyBox?.removeListener(self)
    }
    
    func setupToybox() {
        toyBox?.addListener(self)
    }
    
    func resetConnectedToyObjects() {
        if (connectedToy != nil) {
            connectedToy = nil
            connectedAnyToy = nil
            connectedToyDescriptor = nil
            readyingToyDescriptor = nil
            roller = nil
        }
    }
    
    func startScanning() {
        isDiscovering = true
        toyBox?.startScanning()
        discoveryButton.setTitle("Stop Discovery", for: .normal)
    }
    
    func stopScanning() {
        isDiscovering = false
        toyBox?.stopScanning()
        discoveryButton.setTitle("Start Discovery", for: .normal)
    }
    
    func connect(descriptor: ToyDescriptor) {
        toyBox?.connect(descriptor: descriptor)
    }
    
    func disconnect(descriptor: ToyDescriptor) {
        toyBox?.disconnect(descriptor: descriptor)
    }
    
    @IBAction func discoveryButtonPressed(_ sender: Any) {
        if (!isDiscovering) {
            startScanning()
        } else {
            stopScanning()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "ShowConnectedViewController") {
            let destination = segue.destination as! ConnectedViewController
            destination.delegate = self
            destination.toyBox = toyBox
            destination.descriptor = readyingToyDescriptor
        }
    }
}

extension ViewController: ToyBoxListener {
    public func toyBoxReady(_ toyBox: ToyBox) {
        print("toybox ready")
    }
    
    public func toyBox(_ toyBox: ToyBox, discovered descriptor: ToyDescriptor) {
        discoveredDescriptors.remove(descriptor)
        discoveredDescriptors.insert(descriptor)
        descriptorToRSSI[descriptor] = descriptor.rssi!
        availableConnectionsTableView.reloadData()
        discoveredDescriptorsByRSSI = discoveredDescriptors.sorted(by: { $0.rssi! > $1.rssi! })
    }
    
    public func toyBox(_ toyBox: ToyBox, willReady descriptor: ToyDescriptor) {
    }
    
    public func toyBox(_ toyBox: ToyBox, readied toy: Toy) {
    }
    
    public func toyBox(_ toyBox: ToyBox, putAway toy: Toy) {
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return discoveredDescriptorsByRSSI.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier) as! AvailableConnectionTableViewCell
        let descriptor = discoveredDescriptorsByRSSI[indexPath.row]
        cell.nameLabel.text = descriptor.name
        cell.uuidLabel.text = descriptor.identifier.uuidString
        cell.rssiLabel.text = String(descriptor.rssi!)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        stopScanning()
        let descriptor = discoveredDescriptorsByRSSI[indexPath.row]
        readyingToyDescriptor = descriptor
        performSegue(withIdentifier: "ShowConnectedViewController", sender: self)
    }
}

class AvailableConnectionTableViewCell: UITableViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var uuidLabel: UILabel!
    @IBOutlet weak var rssiLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
}
