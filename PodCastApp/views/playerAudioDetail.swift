//
//  playerAudioDetail.swift
//  PodCastApp
//
//  Created by mohamed zead on 10/8/18.
//  Copyright © 2018 zead. All rights reserved.
//

import Foundation
import UIKit
import AVKit
class PlayerAudioDetail : UIView{
    
    
    static func initFromNib()->PlayerAudioDetail{
        return Bundle.main.loadNibNamed("playerAudioDetails", owner: self, options: nil)?.first as! PlayerAudioDetail
    }
    deinit {
        print("PlayerAudioDetail View has been reclaimed ")
    }
    
    
   var episodeToPlay : Episode!{
        didSet{
            self.playPauseButton.setImage(#imageLiteral(resourceName: "pause"), for: .normal)
            self.miniEpisodeTitle.text = episodeToPlay.title
            self.authorLabel.text = episodeToPlay.author
            self.episodeTitle.text = episodeToPlay.title
            let url = URL(string: episodeToPlay.imageUrl ?? "")
            self.episodeImage.sd_setImage(with: url, completed: nil)
            self.miniEpisodeImage.sd_setImage(with: url, completed: nil)
            self.episodeImage.layer.cornerRadius = 5
            self.episodeImage.clipsToBounds = true
            self.episodeImage.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
            playEpisodeAuto()
        }
    }
    
    
    fileprivate func observePlayerCurrentTime() {
        let interval = CMTimeMake(1, 2)
        player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self](time) in
            self?.currentTimeLabel.text = time.stringToTimerFormat()
            self?.durationLabel.text = self?.player.currentItem?.duration.stringToTimerFormat()
            self?.updatAudioSlider()
        }
    }
    
    
    fileprivate func updatAudioSlider(){
        let current = CMTimeGetSeconds(player.currentTime())
        let duration = CMTimeGetSeconds(player.currentItem?.duration ?? CMTimeMake(1,1))
        let percentage = current/duration
        audioSlider.value = Float(percentage)
    }
    
    
    var panGesture : UIPanGestureRecognizer!
    var dimissalGesture : UIPanGestureRecognizer!
    override func awakeFromNib() {
        super.awakeFromNib()
        dimissalGesture = UIPanGestureRecognizer(target: self, action: #selector(handleDismissalPan))
        mainStackForAllContents.addGestureRecognizer(dimissalGesture)
        self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleMaximize)))
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        miniPlayerView.addGestureRecognizer(panGesture)
        observePlayerCurrentTime()
        let time = CMTimeMake(1,3)
        let times = [NSValue(time: time)]
        player.addBoundaryTimeObserver(forTimes: times, queue: .main) { [weak self] in
            print("finished buffering ")
           self?.enlargeImageView() //enlarge image when stream buffering finished
        }
    }
    
    @objc func handleDismissalPan(gesture : UIPanGestureRecognizer){
         let translation = gesture.translation(in: self.superview)
        if gesture.state == .changed{
            UIView.animate(withDuration: 0, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                self.mainStackForAllContents.transform = CGAffineTransform(translationX: 0, y: translation.y)
            })
        }else if gesture.state == .ended{
            if translation.y > 70{
                let mainTabBarController = UIApplication.shared.keyWindow?.rootViewController as! MainTabBarController
                mainTabBarController.minimizePlayerDetails()
            }else{
                UIView.animate(withDuration: 0, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                  self.mainStackForAllContents.transform = .identity
                })
            }
        }
    }
    
    @objc func handlePan(gesture : UIPanGestureRecognizer){
        if gesture.state == .changed{
            handleGestureChanged(gesture)
        }else if gesture.state == .ended{
            handleGestureEnded(gesture)
        }
        
    }
    
    
    func handleGestureChanged(_ gesture : UIPanGestureRecognizer){
        let translation = gesture.translation(in: superview)
        self.transform = CGAffineTransform(translationX: 0, y: translation.y)
        miniPlayerView.alpha = 1 + translation.y/200
        mainStackForAllContents.alpha = -translation.y/200
    }
    
    
    func handleGestureEnded(_ gesture : UIPanGestureRecognizer){
        let translation = gesture.translation(in: superview)
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            self.transform = .identity
            if translation.y < -200{
                let mainTabBarController = UIApplication.shared.keyWindow?.rootViewController as! MainTabBarController
                mainTabBarController.maximizePlayerDetails(episode: nil)
                self.miniPlayerView.alpha = 0
                self.mainStackForAllContents.alpha = 1
            }else{
                self.miniPlayerView.alpha = 1
                self.mainStackForAllContents.alpha = 0
            }
        })
    }
    
    
    @objc func handleMaximize(){
      let mainTabBarController = UIApplication.shared.keyWindow?.rootViewController as! MainTabBarController
      mainTabBarController.maximizePlayerDetails(episode: nil)
      
    }
    
    
    
    fileprivate func dislargeImageView(){
        UIView.animate(withDuration: 1 , delay: 0.2, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseInOut, animations: {
            self.episodeImage.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
        })
    }
    fileprivate func enlargeImageView(){
        UIView.animate(withDuration: 1 , delay: 0.5, usingSpringWithDamping: 0.5, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            self.episodeImage.transform = .identity
        })
    }
    fileprivate func playEpisodeAuto(){
        guard let url = URL(string: episodeToPlay.audioStreamUrl ) else {return}
        let audioPlayerItem = AVPlayerItem(url: url)
        self.player.replaceCurrentItem(with: audioPlayerItem)
        player.play()
    }
    
    var player : AVPlayer = {
        let audioPlayer = AVPlayer()
        audioPlayer.automaticallyWaitsToMinimizeStalling = false
        return audioPlayer
    }()
    @IBAction func backPressed(_ sender: Any) {
        let mainTabBarController = UIApplication.shared.keyWindow?.rootViewController as! MainTabBarController
        mainTabBarController.minimizePlayerDetails()
        
    }
    @IBOutlet weak var currentTimeLabel: UILabel!
    
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    
    @IBOutlet weak var episodeImage: UIImageView!
    
    @IBOutlet weak var playPauseButton: UIButton!{
        didSet{
            playPauseButton.addTarget(self, action: #selector(playPauseEpisode), for: .touchUpInside)
        }
    }
    
    @objc func playPauseEpisode(){
        if player.timeControlStatus == .paused{
            playPauseButton.setImage(#imageLiteral(resourceName: "pause"), for: .normal)
            miniPlayPauseButton.setImage(#imageLiteral(resourceName: "pause"), for: .normal)
            enlargeImageView()
            player.play()
        }else{
            playPauseButton.setImage(#imageLiteral(resourceName: "play"), for: .normal)
            miniPlayPauseButton.setImage(#imageLiteral(resourceName: "play"), for: .normal)
            dislargeImageView()
            player.pause()
        }
    }
    
    @IBAction func audioSliderDidchange(_ sender: Any) {
        let percentage = audioSlider.value
        guard let duration  = player.currentItem?.duration else {return}
        let durationInSeconds = CMTimeGetSeconds(duration)
        let SeekTimeInSeconds = durationInSeconds * Float64(percentage)
        let seekTime = CMTimeMakeWithSeconds(SeekTimeInSeconds, 1)
        player.seek(to: seekTime )
        player.play()
        
    }
    
    fileprivate func handleRewind(delta : Int64){
        let fifteenSeconds  = CMTimeMake(delta, 1)
        player.currentTime()
        let seekTime = CMTimeAdd(player.currentTime(), fifteenSeconds)
        player.seek(to:seekTime)
    }
    
    @IBAction func fastForwardButtonPressed(_ sender: Any) {
       handleRewind(delta: 15)
    }
    
    @IBAction func rewindButtonPressed(_ sender: Any) {
        handleRewind(delta: -15)
    }
    @IBAction func auidoVolumeDidChange(_ sender: UISlider) {
        player.volume = sender.value
    }
    
    @IBOutlet weak var audioSlider: UISlider!
    
    @IBOutlet weak var episodeTitle: UILabel!{
        didSet{
            episodeTitle.numberOfLines = 0
        }
    }
    
    @IBOutlet weak var mainStackForAllContents: UIStackView!
    @IBOutlet weak var miniPlayerView: UIView!
    @IBOutlet weak var miniEpisodeImage: UIImageView!
    @IBOutlet weak var miniEpisodeTitle: UILabel!
    @IBOutlet weak var miniPlayPauseButton: UIButton!{
        didSet{
            miniPlayPauseButton.addTarget(self, action: #selector(playPauseEpisode), for: .touchUpInside)
        }
    }

}
