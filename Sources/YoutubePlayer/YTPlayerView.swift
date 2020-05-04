//
//  YTPlayerView.swift
//  YouTubeiOSPlayerHelper
//
//  Created by Sacha DSO on 01/05/2020.
//  Copyright © 2020 YouTube Developer Relations. All rights reserved.
//

// Copyright 2014 Google Inc. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import UIKit
import WebKit

/** These enums represent the resolution of the currently loaded video. */
public enum YTPlaybackQuality: String {
    case small
    case medium
    case large
    case hd720
    case hd1080
    case highres
    case auto /** Addition for YouTube Live Events. */
    case `default`
    case unknown /** This should never be returned. It is here for future proofing. */
}

/** These enums represent the state of the current video in the player. */
public enum YTPlayerState: Int {
    case unstarted = -1
    case ended = 0
    case playing = 1
    case paused = 2
    case buffering = 3
    case queued = 5
    case unknown
}

/** These enums represent error codes thrown by the player. */
public enum YTPlayerError: String, Error {
    case invalidParam = "2"
    case html5Error = "5"
    case videoNotFound = "100"
    case cannotFindVideo = "105"
    case notEmbeddable = "101"
    case sameAsNotEmbeddable = "150"
    case unknown
}
// Functionally equivalent error codes 100 and 105 have been collapsed into |kYTPlayerErrorVideoNotFound|.
// Functionally equivalent error codes 101 and 150 have been collapsed into |kYTPlayerErrorNotEmbeddable|.

// Constants representing player callbacks.
enum YTPlayerCallback: String {
    case onReady // "onReady"
    case onStateChange
    case onPlaybackQualityChange
    case onError
    case onPlayTime
    case onYouTubeIframeAPIFailedToLoad
}

/**
* YTPlayerView is a custom UIView that client developers will use to include YouTube
* videos in their iOS applications. It can be instantiated programmatically, or via
* Interface Builder. Use the methods YTPlayerView::loadWithVideoId:,
* YTPlayerView::loadWithPlaylistId: or their variants to set the video or playlist
* to populate the view with.
*/
public class YTPlayerView: UIView {
    
    /** A delegate to be notified on playback events. */
    public weak var delegate: YTPlayerViewDelegate?
    
    var webView: WKWebView! = WKWebView()
    
    private var originURL: URL?
    private var initialLoadingView: UIView?
    
    
    /**
     * This method loads the player with the given video ID and player variables. Player variables
     * specify optional parameters for video playback. For instance, to play a YouTube
     * video inline, the following playerVars dictionary would be used:
     *
     * @code
     * @{ @"playsinline" : @1 };
     * @endcode
     *
     * Note that when the documentation specifies a valid value as a number (typically 0, 1 or 2),
     * both strings and integers are valid values. The full list of parameters is defined at:
     *   https://developers.google.com/youtube/player_parameters?playerVersion=HTML5.
     *
     * This method reloads the entire contents of the WKWebView and regenerates its HTML contents.
     * To change the currently loaded video without reloading the entire WKWebView, use the
     * YTPlayerView::cueVideoById:startSeconds: family of methods.
     *
     * @param videoId The YouTube video ID of the video to load in the player view.
     * @param playerVars An NSDictionary of player parameters.
     * @return YES if player has been configured correctly, NO otherwise.
     */
    @discardableResult
    public func loadWith(videoId: String, playerVars: [String: AnyHashable]? = [String:AnyHashable]()) -> Bool {
        loadWith(playerParams: ["videoId" : videoId, "playerVars" : playerVars])
    }
    
    /**
     * This method loads the player with the given playlist ID and player variables. Player variables
     * specify optional parameters for video playback. For instance, to play a YouTube
     * video inline, the following playerVars dictionary would be used:
     *
     * @code
     * @{ @"playsinline" : @1 };
     * @endcode
     *
     * Note that when the documentation specifies a valid value as a number (typically 0, 1 or 2),
     * both strings and integers are valid values. The full list of parameters is defined at:
     *   https://developers.google.com/youtube/player_parameters?playerVersion=HTML5.
     *
     * This method reloads the entire contents of the WKWebView and regenerates its HTML contents.
     * To change the currently loaded video without reloading the entire WKWebView, use the
     * YTPlayerView::cuePlaylistByPlaylistId:index:startSeconds:
     * family of methods.
     *
     * @param playlistId The YouTube playlist ID of the playlist to load in the player view.
     * @param playerVars An NSDictionary of player parameters.
     * @return YES if player has been configured correctly, NO otherwise.
     */
    func loadWith(playlistId: String, playerVars: [String: AnyHashable]? = [String: AnyHashable]() ) -> Bool {
        // Mutable copy because we may have been passed an immutable config dictionary.
        var tempPlayerVars = playerVars!
        tempPlayerVars["listType"] = "playlist"
        tempPlayerVars["list"] = playlistId
        let playerParams = ["playerVars" : tempPlayerVars]
        return loadWith(playerParams: playerParams)
    }
    
    /**
     * This method loads an iframe player with the given player parameters. Usually you may want to use
     * -loadWithVideoId:playerVars: or -loadWithPlaylistId:playerVars: instead of this method does not handle
     * video_id or playlist_id at all. The full list of parameters is defined at:
     *   https://developers.google.com/youtube/player_parameters?playerVersion=HTML5.
     *
     * @param additionalPlayerParams An NSDictionary of parameters in addition to required parameters
     *                               to instantiate the HTML5 player with. This differs depending on
     *                               whether a single video or playlist is being loaded.
     * @return YES if successful, NO if not.
     */
    func loadWith(playerParams additionalPlayerParams: [String: AnyHashable]?) -> Bool {
        let playerCallbacks = [
            "onReady" : "onReady",
            "onStateChange" : "onStateChange",
            "onPlaybackQualityChange" : "onPlaybackQualityChange",
            "onError" : "onPlayerError"
        ]
        
        var playerParams = [String: AnyHashable]()
        if let additionalPlayerParams = additionalPlayerParams {
            for (k, v) in additionalPlayerParams {
                playerParams[k] = v
            }
        }
        
        if playerParams["height"] == nil {
            playerParams["height"] = "100%"
        }
        if playerParams["width"] == nil {
            playerParams["width"] = "100%"
        }

        playerParams["events"] = playerCallbacks

        if playerParams["playerVars"] != nil {
            let playerVars = playerParams["playerVars"] as! [String: AnyHashable]
            if let urlString = playerVars["origin"] as? String {
                self.originURL = URL(string: urlString)
            } else {
                self.originURL = URL(string:"about:blank")
            }
        } else {
            // This must not be empty so we can render a '{}' in the output JSON
            playerParams["playerVars"] = [String: AnyHashable]()
        }

        // Remove the existing webView to reset any state
        webView.removeFromSuperview()
        webView = createNewWebView()
        addSubview(webView)

        let embedHTMLTemplate = ytPlayerHTMLString
        // Render the playerVars as a JSON dictionary.
        if let jsonData = try? JSONSerialization.data(withJSONObject: playerParams, options: JSONSerialization.WritingOptions.prettyPrinted), let playerVarsJsonString = String(data: jsonData, encoding: .utf8), let originURL = originURL {
            let embedHTML = String(format:embedHTMLTemplate, playerVarsJsonString)
            webView.loadHTMLString(embedHTML, baseURL: originURL)
            webView.navigationDelegate = self
            
            if let initialLoadingView = delegate?.playerViewPreferredInitialLoadingView(playerView: self) {
                initialLoadingView.frame = self.bounds
                initialLoadingView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                addSubview(initialLoadingView)
                self.initialLoadingView = initialLoadingView
            }
            return true
        }
        return false
    }
        
    // MARK: - Player controls
    
    // These methods correspond to their JavaScript equivalents as documented here:
    //   https://developers.google.com/youtube/iframe_api_reference#Playback_controls

    /**
     * Starts or resumes playback on the loaded video. Corresponds to this method from
     * the JavaScript API:
     *   https://developers.google.com/youtube/iframe_api_reference#playVideo
     */
    func playVideo() {
        javascript("player.playVideo();")
    }
    
    /**
     * Pauses playback on a playing video. Corresponds to this method from
     * the JavaScript API:
     *   https://developers.google.com/youtube/iframe_api_reference#pauseVideo
     */
    func pauseVideo() {
        if let url = URL(string: String(format:"ytplayer://onStateChange?data=%@", YTPlayerState.paused.rawValue)) {
            notifyDelegateOfYouTubeCallbackUrl(url: url)
        }
        javascript("player.pauseVideo();")
    }
    
    /**
     * Stops playback on a playing video. Corresponds to this method from
     * the JavaScript API:
     *   https://developers.google.com/youtube/iframe_api_reference#stopVideo
     */
    public func stopVideo() {
        javascript("player.stopVideo();")
    }
    
    /**
     * Seek to a given time on a playing video. Corresponds to this method from
     * the JavaScript API:
     *   https://developers.google.com/youtube/iframe_api_reference#seekTo
     *
     * @param seekToSeconds The time in seconds to seek to in the loaded video.
     * @param allowSeekAhead Whether to make a new request to the server if the time is
     *                       outside what is currently buffered. Recommended to set to YES.
     */
    public func seek(toSeconds: Float, allowSeekAhead: Bool) {
        javascript("player.seekTo(\(toSeconds), \(allowSeekAhead));")
    }
    
    // MARK: - Cueing controls
    
    // Queueing functions for videos. These methods correspond to their JavaScript
    // equivalents as documented here:
    //   https://developers.google.com/youtube/iframe_api_reference#Queueing_Functions
    
    /**
    * Cues a given video by its video ID for playback starting at the given time.
    *  Cueing loads a video, but does not start video playback. This method
    * corresponds with its JavaScript API equivalent as documented here:
    *    https://developers.google.com/youtube/iframe_api_reference#cueVideoById
    *
    * @param videoId A video ID to cue.
    * @param startSeconds Time in seconds to start the video when YTPlayerView::playVideo is called.
    * @param endSeconds Time in seconds to end the video after it begins playing.
    */
    func cueVideoById(_ videoId: String, startSeconds: Float, endSeconds: Float? = nil) {
        if let endSeconds = endSeconds {
            javascript("player.cueVideoById({'videoId': '\(videoId)', 'startSeconds': \(startSeconds), 'endSeconds': \(endSeconds)});")
        } else {
            javascript("player.cueVideoById('\(videoId)', \(startSeconds));")
        }
    }

    /**
    * Loads a given video by its video ID for playback starting at the given time.
    * Loading a video both loads it and begins playback. This method
    * corresponds with its JavaScript API equivalent as documented here:
    *    https://developers.google.com/youtube/iframe_api_reference#loadVideoById
    *
    * @param videoId A video ID to load and begin playing.
    * @param startSeconds Time in seconds to start the video when it has loaded.
    * @param endSeconds Time in seconds to end the video after it begins playing.
    */
    func loadVideoById(videoId: String, startSeconds: Float, endSeconds: Float? = nil) {
        if let endSeconds = endSeconds {
            javascript("player.loadVideoById({'videoId': '\(videoId)', 'startSeconds': \(startSeconds), 'endSeconds': \(endSeconds)});")
        } else {
            javascript("player.loadVideoById('\(videoId)', \(startSeconds));")
        }
    }

    /**
    * Cues a given video by its URL on YouTube.com for playback starting at the given time.
    * Cueing loads a video, but does not start video playback.
    * This method corresponds with its JavaScript API equivalent as documented here:
    *    https://developers.google.com/youtube/iframe_api_reference#cueVideoByUrl
    * @param videoURL URL of a YouTube video to cue for playback.
    * @param startSeconds Time in seconds to start the video when YTPlayerView::playVideo is called.
     * @param endSeconds Time in seconds to end the video after it begins playing.
    */
    func cueVideoByURL(videoURL: String, startSeconds: Float, endSeconds: Float? = nil) {
        if let endSeconds = endSeconds {
            javascript("player.cueVideoByUrl('\(videoURL)', \(startSeconds), \(endSeconds));")
        } else {
            javascript("player.cueVideoByUrl('\(videoURL)', \(startSeconds));")
        }
    }
        
    /**
    * Loads a given video by its video ID for playback starting at the given time.
    * Loading a video both loads it and begins playback. This method
    * corresponds with its JavaScript API equivalent as documented here:
    * https://developers.google.com/youtube/iframe_api_reference#loadVideoByUrl
    *
    * @param videoURL URL of a YouTube video to load and play.
    * @param startSeconds Time in seconds to start the video when it has loaded.
    * @param endSeconds Time in seconds to end the video after it begins playing.
    */
    func loadVideoByURL(_ videoURL: String, startSeconds: Float, endSeconds: Float? = nil) {
        if let endSeconds = endSeconds {
            javascript("player.loadVideoByUrl('\(videoURL)', \(startSeconds), \(endSeconds));")
        } else {
            javascript("player.loadVideoByUrl('\(videoURL)', \(startSeconds));")
        }
    }

    // MARK: - Cueing methods for lists

    // Queueing functions for playlists. These methods correspond to
    // the JavaScript methods defined here:
    //    https://developers.google.com/youtube/js_api_reference#Playlist_Queueing_Functions
    
    /**
    * Cues a given playlist with the given ID. The |index| parameter specifies the 0-indexed
    * position of the first video to play, starting at the given time. Cueing loads a playlist, but does not start video playback. This method
    * corresponds with its JavaScript API equivalent as documented here:
    *    https://developers.google.com/youtube/iframe_api_reference#cuePlaylist
    *
    * @param playlistId Playlist ID of a YouTube playlist to cue.
    * @param index A 0-indexed position specifying the first video to play.
    * @param startSeconds Time in seconds to start the video when YTPlayerView::playVideo is called.
    */
    func cuePlaylistBy(playlistId: String, index: Int, startSeconds: Float) {
        let playlistIdString = String(format: "'%@'", playlistId)
        cuePlaylist(cueingString: playlistIdString, index: index, startSeconds: startSeconds)
    }

    /**
    * Cues a playlist of videos with the given video IDs. The |index| parameter specifies the
    * 0-indexed position of the first video to play, starting at the given time and with the
    * suggested quality. Cueing loads a playlist, but does not start video playback. This method
    * corresponds with its JavaScript API equivalent as documented here:
    *    https://developers.google.com/youtube/iframe_api_reference#cuePlaylist
    *
    * @param videoIds An NSArray of video IDs to compose the playlist of.
    * @param index A 0-indexed position specifying the first video to play.
    * @param startSeconds Time in seconds to start the video when YTPlayerView::playVideo is called.
    */
    func cuePlaylistBy(videoIds:[String], index: Int, startSeconds: Float) {
        cuePlaylist(cueingString: stringFromVideoIdArray(videoIds: videoIds),
                    index: index,
                    startSeconds: startSeconds)
    }
    
    /**
    * Loads a given playlist with the given ID. The |index| parameter specifies the 0-indexed
    * position of the first video to play, starting at the given time.
    * Loading a playlist starts video playback. This method
    * corresponds with its JavaScript API equivalent as documented here:
    *    https://developers.google.com/youtube/iframe_api_reference#loadPlaylist
    *
    * @param playlistId Playlist ID of a YouTube playlist to cue.
    * @param index A 0-indexed position specifying the first video to play.
    * @param startSeconds Time in seconds to start the video when YTPlayerView::playVideo is called.
    */
    func loadPlaylistBy(playlistId: String, index: Int, startSeconds: Float) {
        let playlistIdString = String(format: "'%@'", playlistId)
        loadPlaylist(cueingString: playlistIdString,
                     index: index,
                     startSeconds: startSeconds)
    }
    
    /**
    * Loads a playlist of videos with the given video IDs. The |index| parameter specifies the
    * 0-indexed position of the first video to play, starting at the given time.
    * Loading a playlist starts video playback. This method
    * corresponds with its JavaScript API equivalent as documented here:
    *    https://developers.google.com/youtube/iframe_api_reference#loadPlaylist
    *
    * @param videoIds An NSArray of video IDs to compose the playlist of.
    * @param index A 0-indexed position specifying the first video to play.
    * @param startSeconds Time in seconds to start the video when YTPlayerView::playVideo is called.
    */
    func loadPlaylistByVideos(videoIds: [String], index: Int, startSeconds: Float) {
        loadPlaylist(cueingString: stringFromVideoIdArray(videoIds: videoIds),
                     index: index,
                     startSeconds: startSeconds)
    }

    // MARK: - Setting the playback rate

    /**
    * Gets the playback rate. The default value is 1.0, which represents a video
    * playing at normal speed. Other values may include 0.25 or 0.5 for slower
    * speeds, and 1.5 or 2.0 for faster speeds. This method corresponds to the
    * JavaScript API defined here:
    *   https://developers.google.com/youtube/iframe_api_reference#getPlaybackRate
    *
    * @return An integer value between 0 and 100 representing the current volume.
    */
    func playbackRate(completion: @escaping (Float) -> Void) -> Void {
        javascriptResult("player.getPlaybackRate();") { result in
            if let rate = result as? Float {
                completion(rate)
            }
        }
    }

    /**
    * Sets the playback rate. The default value is 1.0, which represents a video
    * playing at normal speed. Other values may include 0.25 or 0.5 for slower
    * speeds, and 1.5 or 2.0 for faster speeds. To fetch a list of valid values for
    * this method, call YTPlayerView::getAvailablePlaybackRates. This method does not
    * guarantee that the playback rate will change.
    * This method corresponds to the JavaScript API defined here:
    *   https://developers.google.com/youtube/iframe_api_reference#setPlaybackRate
    *
    * @param suggestedRate A playback rate to suggest for the player.
    */
    func setPlaybackRate(suggestedRate: Float) {
        javascript("player.setPlaybackRate(\(suggestedRate));")
    }
    
    /**
    * Gets a list of the valid playback rates, useful in conjunction with
    * YTPlayerView::setPlaybackRate. This method corresponds to the
    * JavaScript API defined here:
    *   https://developers.google.com/youtube/iframe_api_reference#getPlaybackRate
    *
    * @return An NSArray containing available playback rates. nil if there is an error.
    */
    func availablePlaybackRates() -> [String]? {
        //TODO
//        let returnValue = javascript("player.getAvailablePlaybackRates();")
//        if let playbackRateData = returnValue?.data(using: .utf8) {
//            let playbackRates = try? JSONSerialization.jsonObject(with: playbackRateData, options: [])
//            return playbackRates as? [String] ?? [String]()
//        }
        return nil
    }
    
    // MARK: - Setting playback behavior for playlists

    /**
    * Sets whether the player should loop back to the first video in the playlist
    * after it has finished playing the last video. This method corresponds to the
    * JavaScript API defined here:
    *   https://developers.google.com/youtube/iframe_api_reference#loopPlaylist
    *
    * @param loop A boolean representing whether the player should loop.
    */
    func setLoop(_ loop: Bool) {
        javascript("player.setLoop(\(loop));")
    }

    /**
    * Sets whether the player should shuffle through the playlist. This method
    * corresponds to the JavaScript API defined here:
    *   https://developers.google.com/youtube/iframe_api_reference#shufflePlaylist
    *
    * @param shuffle A boolean representing whether the player should
    *                shuffle through the playlist.
    */
    func setShuffle(shuffle: Bool)  {
        javascript("player.setShuffle(\(shuffle));")
    }
    
    // MARK: - Playback status
    
    // These methods correspond to the JavaScript methods defined here:
    //    https://developers.google.com/youtube/js_api_reference#Playback_status

    
    /**
    * Returns a number between 0 and 1 that specifies the percentage of the video
    * that the player shows as buffered. This method corresponds to the
    * JavaScript API defined here:
    *   https://developers.google.com/youtube/iframe_api_reference#getVideoLoadedFraction
    *
    * @return A float value between 0 and 1 representing the percentage of the video
    *         already loaded.
    */
    public func videoLoadedFraction(completion: @escaping (Float) -> Void) {
        javascriptResult("player.getVideoLoadedFraction();") { result in
            if let result = result as? NSNumber {
                completion(result.floatValue)
            }
        }
    }

    /**
    * Returns the state of the player. This method corresponds to the
    * JavaScript API defined here:
    *   https://developers.google.com/youtube/iframe_api_reference#getPlayerState
    *
    * @return |YTPlayerState| representing the state of the player.
    */
    public func playerState(completion: @escaping (YTPlayerState) -> Void)  {
        javascriptResult("player.getPlayerState();") { result in
            if let stateInt = result as? Int, let state = YTPlayerState(rawValue: stateInt) {
                completion(state)
            } else {
                completion(.unknown)
            }
        }
    }

    /**
    * Returns the elapsed time in seconds since the video started playing. This
    * method corresponds to the JavaScript API defined here:
    *   https://developers.google.com/youtube/iframe_api_reference#getCurrentTime
    *
    * @return Time in seconds since the video started playing.
    */
    public func currentTime(completion: @escaping (Float) -> Void) {
        javascriptResult("player.getCurrentTime();") { result in
            if let result = result as? NSNumber {
                completion(result.floatValue)
            }
        }
    }

    
    // MARK: - Retrieving video information

    // Retrieving video information. These methods correspond to the JavaScript
    // methods defined here:
    //   https://developers.google.com/youtube/js_api_reference#Retrieving_video_information
    
    /**
    * Returns the duration in seconds since the video of the video. This
    * method corresponds to the JavaScript API defined here:
    *   https://developers.google.com/youtube/iframe_api_reference#getDuration
    *
    * @return Length of the video in seconds.
    */
    public func duration(completion: @escaping (TimeInterval) -> Void) {
        javascriptResult("player.getDuration();") { result in
            if let result = result as? NSNumber {
                completion(result.doubleValue)
            }
        }
    }

    /**
    * Returns the YouTube.com URL for the video. This method corresponds
    * to the JavaScript API defined here:
    *   https://developers.google.com/youtube/iframe_api_reference#getVideoUrl
    *
    * @return The YouTube.com URL for the video. Returns nil if no video is loaded yet.
    */
    public func videoUrl(completion: @escaping (URL) -> Void) {
        javascriptResult("player.getVideoUrl();") { result in
            if let urlString = result as? String, let url = URL(string: urlString) {
                completion(url)
            }
        }
    }

    /**
    * Returns the embed code for the current video. This method corresponds
    * to the JavaScript API defined here:
    *   https://developers.google.com/youtube/iframe_api_reference#getVideoEmbedCode
    *
    * @return The embed code for the current video. Returns nil if no video is loaded yet.
    */
    public func videoEmbedCode(completion: @escaping (String) -> Void) {
        javascriptResult("player.getVideoEmbedCode();") { result in
            if let result = result as? String {
                completion(result)
            }
        }
    }

    // MARK: - Retrieving playlist information
    
    // Retrieving playlist information. These methods correspond to the
    // JavaScript defined here:
    //    https://developers.google.com/youtube/js_api_reference#Retrieving_playlist_information

    /**
    * Returns an ordered array of video IDs in the playlist. This method corresponds
    * to the JavaScript API defined here:
    *   https://developers.google.com/youtube/iframe_api_reference#getPlaylist
    *
    * @return An NSArray containing all the video IDs in the current playlist. |nil| on error.
    */
    func playlist() -> [String] {
        //TODO
//        let returnValue = javascript("player.getPlaylist();")
//        if let playlistData = returnValue?.data(using: .utf8) {
//            let videoIds = try? JSONSerialization.jsonObject(with: playlistData, options: [])
//            return videoIds as? [String] ?? [String]()
//        }
        return [String]()
    }
    
    /**
    * Returns the 0-based index of the currently playing item in the playlist.
    * This method corresponds to the JavaScript API defined here:
    *   https://developers.google.com/youtube/iframe_api_reference#getPlaylistIndex
    *
    * @return The 0-based index of the currently playing item in the playlist.
    */
    public func playlistIndex(completion: @escaping (Int) -> Void) {
        javascriptResult("player.getPlaylistIndex();") { result in
            if let result = result as? NSNumber {
                completion(result.intValue)
            }
        }
    }

    // MARK: - Playing a video in a playlist
    
    // These methods correspond to the JavaScript API as defined under the
    // "Playing a video in a playlist" section here:
    //    https://developers.google.com/youtube/iframe_api_reference#Playback_status

    /**
    * Loads and plays the next video in the playlist. Corresponds to this method from
    * the JavaScript API:
    *   https://developers.google.com/youtube/iframe_api_reference#nextVideo
    */
    func nextVideo() {
        javascript("player.nextVideo();")
    }

    /**
    * Loads and plays the previous video in the playlist. Corresponds to this method from
    * the JavaScript API:
    *   https://developers.google.com/youtube/iframe_api_reference#previousVideo
    */
    func previousVideo() {
        javascript("player.previousVideo();")
    }

    /**
    * Loads and plays the video at the given 0-indexed position in the playlist.
    * Corresponds to this method from the JavaScript API:
    *   https://developers.google.com/youtube/iframe_api_reference#playVideoAt
    *
    * @param index The 0-indexed position of the video in the playlist to load and play.
    */
    func playVideoAt(index: Int) {
        javascript("player.playVideoAt(\(index));")
    }

    /**
     * Convert a quality value from NSString to the typed enum value.
     *
     * @param qualityString A string representing playback quality. Ex: "small", "medium", "hd1080".
     * @return An enum value representing the playback quality.
     */
    func playbackQualityForString(_ qualityString: String) -> YTPlaybackQuality {
        return YTPlaybackQuality(rawValue: qualityString) ?? YTPlaybackQuality.unknown
    }

    // MARK: - Private methods

    /**
     * Private method to handle "navigation" to a callback URL of the format
     * ytplayer://action?data=someData
     * This is how the WKWebView communicates with the containing Objective-C code.
     * Side effects of this method are that it calls methods on this class's delegate.
     *
     * @param url A URL of the format ytplayer://action?data=value.
     */
    private func notifyDelegateOfYouTubeCallbackUrl(url: URL)  {
        guard let action = YTPlayerCallback(rawValue: url.host ?? "") else {
            return
        }
    
        // We know the query can only be of the format ytplayer://action?data=SOMEVALUE,
        // so we parse out the value.
        let query = url.query
        let data = query?.components(separatedBy: "=").last
        
        switch action {
        case .onReady:
            initialLoadingView?.removeFromSuperview()
            delegate?.playerViewDidBecomeReady(playerView: self)
        case .onStateChange:
            if let dataInt = Int(data!) {
                let state = YTPlayerState(rawValue: dataInt) ?? .unknown
                delegate?.playerView(playerView: self, didChangeTo: state)
            }
        case .onPlaybackQualityChange:
            let quality = playbackQualityForString(data!)
            delegate?.playerView(playerView: self, didChangeTo: quality)
        case .onError:
            let error = YTPlayerError(rawValue: data ?? "") ?? .unknown
            delegate?.playerView(playerView: self, didReceiveError: error)
        case .onPlayTime:
            let time: Float = (data as NSString?)?.floatValue ?? 0
            delegate?.playerView(playerView: self, didPlayTime: time)
        case .onYouTubeIframeAPIFailedToLoad:
            initialLoadingView?.removeFromSuperview()
        }
    }

    func handleHttpNavigationToUrl(url: URL) -> Bool {
        // Usually this means the user has clicked on the YouTube logo or an error message in the
        // player. Most URLs should open in the browser. The only http(s) URL that should open in this
        // WKWebView is the URL for the embed, which is of the format:
        //     http(s)://www.youtube.com/embed/[VIDEO ID]?[PARAMETERS]
        
        let kYTPlayerEmbedUrlRegexPattern = "^http(s)://(www.)youtube.com/embed/(.*)$"
        let kYTPlayerAdUrlRegexPattern = "^http(s)://pubads.g.doubleclick.net/pagead/conversion/"
        let kYTPlayerOAuthRegexPattern = "^http(s)://accounts.google.com/o/oauth2/(.*)$"
        let kYTPlayerStaticProxyRegexPattern = "^https://content.googleapis.com/static/proxy.html(.*)$"
        let kYTPlayerSyndicationRegexPattern = "^https://tpc.googlesyndication.com/sodar/(.*).html$"
        
        let range = NSRange(location: 0, length: url.absoluteString.count)
        
        let ytRegex = try! NSRegularExpression(pattern: kYTPlayerEmbedUrlRegexPattern,
                                               options: NSRegularExpression.Options.caseInsensitive)
        let ytMatch = ytRegex.firstMatch(in: url.absoluteString,
                                    options: [], range: range)
        
        let adRegex = try! NSRegularExpression(pattern: kYTPlayerAdUrlRegexPattern,
                                          options: NSRegularExpression.Options.caseInsensitive)
        let adMatch = adRegex.firstMatch(in: url.absoluteString,
                                    options: [], range: range)
        
        let syndicationRegex = try! NSRegularExpression(pattern: kYTPlayerSyndicationRegexPattern,
                                          options: NSRegularExpression.Options.caseInsensitive)
        let syndicationMatch = syndicationRegex.firstMatch(in: url.absoluteString,
                                    options: [], range: range)
        
        let oauthRegex = try! NSRegularExpression(pattern: kYTPlayerOAuthRegexPattern,
                                          options: NSRegularExpression.Options.caseInsensitive)
        let oauthMatch = oauthRegex.firstMatch(in: url.absoluteString,
                                    options: [], range: range)
        
        let staticProxyRegex = try! NSRegularExpression(pattern: kYTPlayerStaticProxyRegexPattern,
                                          options: NSRegularExpression.Options.caseInsensitive)
        let staticProxyMatch = staticProxyRegex.firstMatch(in: url.absoluteString,
                                    options: [], range: range)

      if (ytMatch != nil || adMatch != nil || oauthMatch != nil || staticProxyMatch != nil || syndicationMatch != nil) {
            return true
      } else {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            return false
        }
    }

    /**
     * Private method for cueing both cases of playlist ID and array of video IDs. Cueing
     * a playlist does not start playback.
     *
     * @param cueingString A JavaScript string representing an array, playlist ID or list of
     *                     video IDs to play with the playlist player.
     * @param index 0-index position of video to start playback on.
     * @param startSeconds Seconds after start of video to begin playback.
     * @return The result of cueing the playlist.
     */
    func cuePlaylist(cueingString: String,
                     index: Int,
                     startSeconds: Float) {
        javascript("player.cuePlaylist(\(cueingString), \(index), \(startSeconds));")
    }

    /**
     * Private method for loading both cases of playlist ID and array of video IDs. Loading
     * a playlist automatically starts playback.
     *
     * @param cueingString A JavaScript string representing an array, playlist ID or list of
     *                     video IDs to play with the playlist player.
     * @param index 0-index position of video to start playback on.
     * @param startSeconds Seconds after start of video to begin playback.
     * @return The result of cueing the playlist.
     */
    func loadPlaylist(cueingString: String,
                      index: Int,
                      startSeconds: Float) {
        javascript("player.loadPlaylist(\(cueingString), \(index), \(startSeconds));")
    }

    /**
     * Private helper method for converting an NSArray of video IDs into its JavaScript equivalent.
     *
     * @param videoIds An array of video ID strings to convert into JavaScript format.
     * @return A JavaScript array in String format containing video IDs.
     */
    func stringFromVideoIdArray(videoIds: [String]) -> String {
       var formattedVideoIds = [String]()
        for unformattedId in videoIds {
            formattedVideoIds.append(String(format: "'%@'", unformattedId))
        }
        return String(format: "[%@]", formattedVideoIds.joined(separator: ", "))
    }

    /**
     * Private method for evaluating JavaScript in the WebView.
     *
     * @param jsToExecute The JavaScript code in string format that we want to execute.
     * @return JavaScript response from evaluating code.
     */
    func javascript(_ javascript: String) {
        webView.evaluateJavaScript(javascript, completionHandler: nil)
    }
    
    func javascriptResult(_ javascript: String, completion: @escaping (Any) -> Void) {
        webView.evaluateJavaScript(javascript, completionHandler: { result, error in
            if let result = result {
                completion(result)
            }
        })
    }

    func createNewWebView() -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.allowsPictureInPictureMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        let webView = WKWebView(frame: bounds, configuration: config)
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight ]
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        if let color = delegate?.playerViewPreferredWebViewBackgroundColor(playerView: self) {
            webView.backgroundColor = color
            if color == .clear {
                webView.isOpaque = false
            }
        }
        return webView
    }

    /**
    * Removes the internal web view from this player view.
    * Intended to use for testing, should not be used in production code.
    */
    func removeWebView() {
        webView.removeFromSuperview()
        webView = nil
    }
}


extension YTPlayerView: WKNavigationDelegate {
    
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let request = navigationAction.request
        if request.url?.host == originURL?.host {
            decisionHandler(.allow)
            return
        } else if request.url?.scheme == "ytplayer" {
            notifyDelegateOfYouTubeCallbackUrl(url: request.url!)
            decisionHandler(.cancel)
            return
         } else if request.url?.scheme == "http" || request.url?.scheme == "https" {
            if handleHttpNavigationToUrl(url: request.url!) {
                decisionHandler(.allow)
            } else {
                decisionHandler(.cancel)
            }
            return
         }
        decisionHandler(.allow)
    }

    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        initialLoadingView?.removeFromSuperview()
    }
}
