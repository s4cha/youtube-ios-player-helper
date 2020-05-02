//
//  YTPlayerViewDelegate.swift
//  YouTubeiOSPlayerHelper
//
//  Created by Sacha DSO on 02/05/2020.
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

/**
* A delegate for ViewControllers to respond to YouTube player events outside
* of the view, such as changes to video playback state or playback errors.
* The callback functions correlate to the events fired by the IFrame API.
* For the full documentation, see the IFrame documentation here:
*     https://developers.google.com/youtube/iframe_api_reference#Events
*/
public protocol YTPlayerViewDelegate: class {
    /**
     * Invoked when the player view is ready to receive API calls.
     *
     * @param playerView The YTPlayerView instance that has become ready.
     */
    func playerViewDidBecomeReady(playerView: YTPlayerView)
    
    /**
    * Callback invoked when player state has changed, e.g. stopped or started playback.
    *
    * @param playerView The YTPlayerView instance where playback state has changed.
    * @param state YTPlayerState designating the new playback state.
    */
    func playerViewDidChangeToState(playerView: YTPlayerView, state: YTPlayerState)
    
    /**
     * Callback invoked when playback quality has changed.
     *
     * @param playerView The YTPlayerView instance where playback quality has changed.
     * @param quality YTPlaybackQuality designating the new playback quality.
     */
    func playerViewDidChangeToQuality(playerView: YTPlayerView, quality: YTPlaybackQuality)
    
    /**
     * Callback invoked when an error has occured.
     *
     * @param playerView The YTPlayerView instance where the error has occurred.
     * @param error YTPlayerError containing the error state.
     */
    func playerViewReceivedError(playerView: YTPlayerView, error: YTPlayerError)
    
    /**
     * Callback invoked frequently when playBack is playing.
     *
     * @param playerView The YTPlayerView instance where the error has occurred.
     * @param playTime float containing curretn playback time.
     */
    func playerViewDidPlayTime(playerView: YTPlayerView, playTime: Float)
    
    /**
     * Callback invoked when setting up the webview to allow custom colours so it fits in
     * with app color schemes. If a transparent view is required specify clearColor and
     * the code will handle the opacity etc.
     *
     * @param playerView The YTPlayerView instance where the error has occurred.
     * @return A color object that represents the background color of the webview.
     */
    func playerViewPreferredWebViewBackgroundColor(playerView: YTPlayerView) -> UIColor
    
    /**
     * Callback invoked when initially loading the YouTube iframe to the webview to display a custom
     * loading view while the player view is not ready. This loading view will be dismissed just before
     * -playerViewDidBecomeReady: callback is invoked. The loading view will be automatically resized
     * to cover the entire player view.
     *
     * The default implementation does not display any custom loading views so the player will display
     * a blank view with a background color of (-playerViewPreferredWebViewBackgroundColor:).
     *
     * Note that the custom loading view WILL NOT be displayed after iframe is loaded. It will be
     * handled by YouTube iframe API. This callback is just intended to tell users the view is actually
     * doing something while iframe is being loaded, which will take some time if users are in poor networks.
     *
     * @param playerView The YTPlayerView instance where the error has occurred.
     * @return A view object that will be displayed while YouTube iframe API is being loaded.
     *         Pass nil to display no custom loading view. Default implementation returns nil.
     */
    func playerViewPreferredInitialLoadingView(playerView: YTPlayerView) -> UIView?
}

public extension YTPlayerViewDelegate {
    func playerViewDidChangeToState(playerView: YTPlayerView, state: YTPlayerState) { }
    func playerViewDidChangeToQuality(playerView: YTPlayerView, quality: YTPlaybackQuality) { }
    func playerViewReceivedError(playerView: YTPlayerView, error: YTPlayerError) { }
    func playerViewDidPlayTime(playerView: YTPlayerView, playTime: Float) { }
    func playerViewPreferredWebViewBackgroundColor(playerView: YTPlayerView) -> UIColor { .black }
    func playerViewPreferredInitialLoadingView(playerView: YTPlayerView) -> UIView? { nil }
}
