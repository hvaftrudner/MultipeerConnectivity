//
//  ViewController.swift
//  project 25
//
//  Created by Kristoffer Eriksson on 2020-11-17.
//
import MultipeerConnectivity
import UIKit

class ViewController: UICollectionViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, MCSessionDelegate, MCBrowserViewControllerDelegate {
    
    var images = [UIImage]()
    
    var peerId = MCPeerID(displayName: UIDevice.current.name)
    var mcSession: MCSession?
    var mcAdvertiserAssistant: MCAdvertiserAssistant?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        title = "selfie share"
        
        let shareMessage = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(sendMessage))
        let choosePicture = UIBarButtonItem(barButtonSystemItem: .camera, target: self, action: #selector(importPicture))
        
        let showConnection = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(showConnectionPrompt))
        let showPeers = UIBarButtonItem(title: "peer", style: .plain, target: self, action: #selector(showConnected))
        
        navigationItem.rightBarButtonItems = [shareMessage, choosePicture]
        navigationItem.leftBarButtonItems = [showConnection, showPeers]
        
        
        mcSession = MCSession(peer: peerId, securityIdentity: nil, encryptionPreference: .required)
        mcSession?.delegate = self
        
    }
    @objc func showConnected(){
        var connected = ""
        
        guard let mcSession = mcSession else {return}
        if mcSession.connectedPeers.count > 0 {
            for peer in mcSession.connectedPeers {
                connected.append(peer.displayName)
            }
            let ac = UIAlertController(title: "Connected: ", message: "\(connected)", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "ok", style: .default))
            present(ac, animated: true)
        } else {
            let ac = UIAlertController(title: "No one connected", message: nil, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "ok", style: .default))
            present(ac, animated: true)
        }
    }
    
    func startHosting(action: UIAlertAction){
        guard let mcSession = mcSession else {return}
        mcAdvertiserAssistant = MCAdvertiserAssistant(serviceType: "HWS-project25", discoveryInfo: nil, session: mcSession)
        mcAdvertiserAssistant?.start()
    }
    func joinSession(action: UIAlertAction){
        guard let mcSession = mcSession else {return}
        let mcBrowser = MCBrowserViewController(serviceType: "HWS-project25", session: mcSession)
        mcBrowser.delegate = self
        present(mcBrowser, animated: true)
    }
    //gets error use popoverpresentationcontr to return to own view
    func disconnectFromSession(action: UIAlertAction){
        guard let mcSession = mcSession else {return}
        mcSession.disconnect()
    }
    
    //Send message functions
    @objc func sendMessage(){
        let ac = UIAlertController(title: "Send message", message: nil, preferredStyle: .alert)
        ac.addTextField()
        ac.addAction(UIAlertAction(title: "Message", style: .default) { [weak self, weak ac] _ in
            if let text = ac?.textFields?[0].text {
                self?.send(text)
            }
            
        })
        present(ac, animated: true)
    }
    
    
    func send(_ string: String){
        
        let data = Data(string.utf8)
        sendData(data)
    }
    func sendData(_ data: Data){
        guard let mcSession = mcSession else {return}
        if mcSession.connectedPeers.count > 0 {
            
                do {
                    try mcSession.send(data, toPeers: mcSession.connectedPeers, with: .reliable)
                    
                } catch {
                    let ac = UIAlertController(title: "send error", message: error.localizedDescription, preferredStyle: .alert)
                    ac.addAction(UIAlertAction(title: "ok", style: .default))
                    present(ac, animated: true)
                }
            
        }
    }
    
    //Collectionview
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "imageView", for: indexPath)
        if let imageView = cell.viewWithTag(1000) as? UIImageView{
            imageView.image = images[indexPath.item]
        }
        
        return cell
    }
    
    //Image picker
    @objc func importPicture(){
        let picker = UIImagePickerController()
        picker.allowsEditing = true
        picker.delegate = self
        
        present(picker, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.editedImage] as? UIImage else {return}
        dismiss(animated: true)
        
        images.insert(image, at: 0)
        collectionView.reloadData()
        
        guard let mcSession = mcSession else {return}
        if mcSession.connectedPeers.count > 0 {
            if let imageData = image.pngData(){
                do {
                    try mcSession.send(imageData, toPeers: mcSession.connectedPeers, with: .reliable)
                    
                } catch {
                    let ac = UIAlertController(title: "send error", message: error.localizedDescription, preferredStyle: .alert)
                    ac.addAction(UIAlertAction(title: "ok", style: .default))
                    present(ac, animated: true)
                }
            }
        }
    }
    //Connection methods
    @objc func showConnectionPrompt(){
        let ac = UIAlertController(title: "Connect to others", message: nil, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Host a session", style: .default, handler: startHosting))
        ac.addAction(UIAlertAction(title: "Join a session", style: .default, handler: joinSession))
        ac.addAction(UIAlertAction(title: "Disconnect from session", style: .default, handler: disconnectFromSession))
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(ac, animated: true)
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
    }
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        
    }
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true)
    }
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true)
    }
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state{
        case .connected:
            print("Connected: \(peerID.displayName)")
        case .connecting:
            print("Connecting: \(peerID.displayName)")
        case .notConnected:
            print("Not connected: \(peerID.displayName)")
            
            let ac = UIAlertController(title: "Disconnected", message: "\(peerID.displayName) disconnected", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "ok", style: .default))
            present(ac, animated: true)
            
        @unknown default:
            print("unknown state recieved: \(peerId.displayName)")
        }
    }
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        DispatchQueue.main.async {
            [weak self] in
            if let image = UIImage(data: data){
                self?.images.insert(image, at: 0)
                self?.collectionView.reloadData()
            } else {
                let string = String(decoding: data, as: UTF8.self)
                let ac = UIAlertController(title: "message from \(peerID.displayName)", message: "\(string)", preferredStyle: .alert)
                ac.addAction(UIAlertAction(title: "ok", style: .default))
                self?.present(ac, animated: true)
            }
        }
    }
}

