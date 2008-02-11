// OverlayMessage.js - HTML transparent overlaid message
//
// Using these routines is very easy.
//
// 1) In your HTML, make an element for the message to appear over.  Give
//    it whatever style attributes you like:
//
//        <div id="container" style="width: 100%; height: 7in;"></div>
//
// 2) Load the routines into your code:
//
//        <script src="http://www.acme.com/javascript/OverlayMessage.js" type="text/javascript"></script>
//
// 3) Create an OverlayMessage object, passing it the HTML element:
//
//        var om = new OverlayMessage( document.getElementById( 'container' ) );
//
// 4) Call the Set method when you want a message to appear:
//
//        om.Set( 'Loading...' );
//
// 5) Call the Clear method when you want the message to go away:
//
//        om.Clear();
//
// That's it!  Everything else happens automatically.
//
//
// The current version of this code is always available at:
// http://www.acme.com/javascript/
//
//
// Copyright © 2006 by Jef Poskanzer <jef@mail.acme.com>.
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions
// are met:
// 1. Redistributions of source code must retain the above copyright
//    notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in the
//    documentation and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
// ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
// OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
// HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
// LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
// OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
// SUCH DAMAGE.
//
// For commentary on this license please see http://www.acme.com/license.html


OverlayMessage = function ( container )
    {
    // Terminology:
    // +-----------------+
    // |wrapper          |
    // |+---------------+|
    // ||container      ||
    // ||   +-------+   ||
    // ||   |overlay|   ||
    // ||   +-------+   ||
    // ||               ||
    // |+---------------+|
    // +-----------------+

    // Get the parent.
    var parent = container.parentNode;

    // Make the wrapper div.
    var wrapper = document.createElement( 'div' );
    wrapper.style.cssText = container.style.cssText;
    parent.insertBefore( wrapper, container );

    // Move the container into the wrapper.
    parent.removeChild( container );
    wrapper.appendChild( container );
    container.style.cssText = 'position: relative; width: 100%; height: 100%;';

    // Add the overlay div.
    this.overlay = document.createElement( 'div' );
    wrapper.appendChild( this.overlay );
    this.visibleStyle = 'position: relative; top: -55%; background-color: ' + OverlayMessage.backgroundColor + '; width: 40%; text-align: center; margin-left: auto; margin-right: auto; padding: 2em; border: 0.08in ridge ' + OverlayMessage.borderColor + '; z-index: 100; opacity: .75; filter: alpha(opacity=75);';
    this.invisibleStyle = 'display: none;';
    this.overlay.style.cssText = this.invisibleStyle;
    };


OverlayMessage.backgroundColor = '#eeeeee';
OverlayMessage.borderColor = '#eeeeee';


OverlayMessage.prototype.Set = function ( message )
    {
    this.overlay.innerHTML = message;
    this.overlay.style.cssText = this.visibleStyle;
    };


OverlayMessage.prototype.Clear = function ()
    {
    this.overlay.style.cssText = this.invisibleStyle;
    };


OverlayMessage.SetBackgroundColor = function ( color )
    {
    OverlayMessage.backgroundColor = color;
    };


OverlayMessage.SetBorderColor = function ( color )
    {
    OverlayMessage.borderColor = color;
    };
