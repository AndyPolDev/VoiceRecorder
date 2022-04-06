// Создать приложение для записи и последующего воспроизведения голоса (диктофон)


import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var recordButtonLabel: UIButton!
    @IBOutlet weak var playButtonLabel: UIButton!
    
    var audioRecorder: AVAudioRecorder?
    var audioPlayer: AVAudioPlayer?
    var timer = Timer()
    var isAudioRecordingGranted: Bool?
    var isRecording = false
    var isPlaying = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        checkRecordPermission()
        
    }
    
    @IBAction func recordButtonPressed(_ sender: UIButton) {
        if isRecording {
            finishAudioRecording(success: true)
            recordButtonLabel.setTitle("Record", for: .normal)
            playButtonLabel.isEnabled = true
            isRecording = false
        } else {
            setupRecorder()
            if let safeAudioRecorder = audioRecorder {
                safeAudioRecorder.record()
                timer = Timer.scheduledTimer(timeInterval: 0.1, target:self, selector:#selector(self.updateTimer(timer:)), userInfo: nil, repeats: true)
                recordButtonLabel.setTitle("Stop", for: .normal)
                playButtonLabel.isEnabled = false
                isRecording = true
            }
        }
    }
    
    @IBAction func playButtonPressed(_ sender: UIButton) {
        if isPlaying {
            if let safeAudioPlayer = audioPlayer {
                safeAudioPlayer.stop()
                recordButtonLabel.isEnabled = true
                playButtonLabel.setTitle("Play", for: .normal)
                isPlaying = false
            }
        } else {
            if FileManager.default.fileExists(atPath: getFileUrl().path) {
                recordButtonLabel.isEnabled = false
                playButtonLabel.setTitle("Stop", for: .normal)
                prepare_play()
                isPlaying = true
                if let safeAudioPlayer = audioPlayer {
                    safeAudioPlayer.play()
                }
            } else {
                displayAlert(messageTitle: "Error", message: "Audio file is missing.", actionTitle: "OK")
            }
        }
    }
    
    func checkRecordPermission() {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            isAudioRecordingGranted = true
            break
        case .denied:
            isAudioRecordingGranted = false
            break
        case .undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission { allowed in
                if allowed {
                    self.isAudioRecordingGranted = true
                } else {
                    self.isAudioRecordingGranted = false
                }
            }
            break
        default:
            break
        }
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    func getFileUrl() -> URL {
        let filename = "myRecording.m4a"
        let filePath = getDocumentsDirectory().appendingPathComponent(filename)
        return filePath
    }
    
    func setupRecorder() {
        if let safeIsAudioRecordingGranted = isAudioRecordingGranted {
            if safeIsAudioRecordingGranted {
                let session = AVAudioSession.sharedInstance()
                do {
                    try session.setCategory(AVAudioSession.Category.playAndRecord, options: .defaultToSpeaker)
                    try session.setActive(true)
                    let settings = [
                        AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                        AVSampleRateKey: 44100,
                        AVNumberOfChannelsKey: 2,
                        AVEncoderAudioQualityKey:AVAudioQuality.high.rawValue
                    ]
                    
                    audioRecorder = try AVAudioRecorder(url: getFileUrl(), settings: settings)
                    if let safeAudioRecorder = audioRecorder {
                        safeAudioRecorder.delegate = self
                        safeAudioRecorder.isMeteringEnabled = true
                        safeAudioRecorder.prepareToRecord()
                    }
                    
                    
                } catch {
                    displayAlert(messageTitle: "Error", message: error.localizedDescription, actionTitle: "OK")
                }
            }
            else
            {
                displayAlert(messageTitle: "Error", message: "Don't have access to use your microphone.", actionTitle: "OK")
            }
        }
    }
    
    @objc func updateTimer(timer: Timer) {
        if let safeAudioRecorder = audioRecorder {
            if safeAudioRecorder.isRecording {
                let hr = Int((safeAudioRecorder.currentTime / 60) / 60)
                let min = Int(safeAudioRecorder.currentTime / 60)
                let sec = Int(safeAudioRecorder.currentTime.truncatingRemainder(dividingBy: 60))
                let totalTimeString = String(format: "%02d:%02d:%02d", hr, min, sec)
                timerLabel.text = totalTimeString
                safeAudioRecorder.updateMeters()
            }
        }
    }
    
    
    func finishAudioRecording(success: Bool) {
        if success {
            if let safeAudioRecorder = audioRecorder {
                safeAudioRecorder.stop()
                audioRecorder = nil
                timer.invalidate()
                print("recorded successfully.")
            }
        }
        else {
            displayAlert(messageTitle: "Error", message: "Recording failed.", actionTitle: "OK")
        }
    }
    
    func prepare_play() {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: getFileUrl())
            if let safeAudioPlayer = audioPlayer {
                safeAudioPlayer.delegate = self
                safeAudioPlayer.prepareToPlay()
            }
        }
        catch{
            print("Error")
        }
    }
    
    func displayAlert(messageTitle: String , message: String , actionTitle: String)
    {
        let allertController = UIAlertController(title: messageTitle, message: message, preferredStyle: .alert)
        allertController.addAction(UIAlertAction(title: actionTitle, style: .default){ (result : UIAlertAction) -> Void in
            _ = self.navigationController?.popViewController(animated: true)
        })
        present(allertController, animated: true)
    }
    
    
}

extension ViewController: AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            finishAudioRecording(success: false)
        }
        playButtonLabel.isEnabled = true
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool){
        recordButtonLabel.isEnabled = true
    }
}
