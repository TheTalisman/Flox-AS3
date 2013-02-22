// =================================================================================================
//
//	Flox AS3
//	Copyright 2013 Gamua OG. All Rights Reserved.
//
// =================================================================================================

package com.gamua.flox
{
    import com.gamua.flox.utils.HttpMethod;
    import com.gamua.flox.utils.createUID;
    import com.gamua.flox.utils.execute;
    
    import flash.errors.IllegalOperationError;
    
    /** An Entity that contains information about a Flox Player. */
    [Type(".player")]
    public class Player extends Entity
    {
        private var mAuthType:String;
        private var mAuthId:String;
        
        public function Player()
        {
            super.ownerId = this.id;
            
            mAuthType = AuthenticationType.GUEST;
            mAuthId = createUID();
        }
        
        /** Log in a player with the given authentication information. If you pass no
         *  parameters, a new guest will be logged in; the 'Flox.currentPlayer' parameter will
         *  immediately reference that player.
         * 
         *  <p>Flox requires that there's always a player logged in. Thus, there is no 'logout'  
         *  method. If you want to remove the reference to the current player, just call  
         *  'login' again (without arguments). The previous player will then be replaced 
         *  by a new guest.</p> 
         *  
         *  @param authType:    The type of authentication you want to use.
         *  @param authID:      The id of the player in its authentication system.
         *  @param authToken:   The token you received from the player's authentication system.  
         *  @param onComplete:  function onComplete(currentPlayer:Player):void;
         *  @param onError:     function onError(error:String, httpStatus:int):void;
         */
        public static function login(
            authType:String="guest", authId:String=null, authToken:String=null,
            onComplete:Function=null, onError:Function=null):void
        {
            Flox.checkInitialized();
            
            if (authType == AuthenticationType.GUEST)
            {
                if (authId == null) authId = createUID();
                if (authToken == null) authToken = createUID();

                var player:Player = new Flox.playerClass();
                player.authId = authId;
                player.authType = authType;
                
                onAuthenticated(player);
            }
            else if (authType == AuthenticationType.EMAIL)
            {
                var authData:Object = { id: current.id, authType: authType, 
                                        authId: authId, authToken: authToken };
                
                Flox.service.request(HttpMethod.POST, "authenticate", authData, 
                                     onRequestComplete, onError);
            }
            else
            {
                throw new ArgumentError("Authentication type not supported: " + authType);
            }
            
            function onRequestComplete(body:Object, httpStatus:int):void
            {
                var id:String = body.id;
                var type:String = getType(Flox.playerClass);
                var eTag:String = body.eTag;
                var player:Player = Entity.fromObject(type, id, body.entity) as Player;
                onAuthenticated(player);
            }
            
            function onAuthenticated(player:Player):void
            {
                Flox.clearCache();
                Flox.authentication = new Authentication(player.id, authType, authId, authToken);
                Flox.currentPlayer = player;
                execute(onComplete, player);
            }
        }
        
        /** Logs the current player out and immediately creates a new guest player.
         *  (In Flox, 'Player.current' should always return a player object.) */
        public static function logout():void
        {
            // we always need an active player! The login method, called without arguments,
            // will create a new one for us.
            
            login();
        }
        
        /** Log in a player with his email address. 
         * 
         *  <ul><li>If this is the first time this email address
         *  is used, the current guest player will be converted into a player with auth-type
         *  "email".</li>
         *  <li>When the player tries to log in with the same address on another device,
         *  he will get an e-mail with a confirmation link, and the login will fail until the
         *  player clicks on that link. You will get an error with http status '403' (forbidden)
         *  until then.</li></ul> 
         *  
         *  @param email:      The e-mail address of the player trying to log in.  
         *  @param onComplete: function onComplete(currentPlayer:Player):void;
         *  @param onError:    function onError(error:String, httpStatus:int):void;*/ 
        public static function loginWithEmail(email:String, 
                                              onComplete:Function, onError:Function):void
        {
            login(AuthenticationType.EMAIL, email, Flox.installationID, onComplete, onError);
        }
        
        /** The current local player. */
        public static function get current():Player
        {
            return Flox.currentPlayer;
        }

        public function get authType():String { return mAuthType; }
        public function set authType(value:String):void { mAuthType = value; }
        
        public function get authId():String { return mAuthId; }
        public function set authId(value:String):void { mAuthId = value; }
        
        public override function set publicAccess(value:String):void
        {
            if (value != Access.READ_WRITE)
                throw new IllegalOperationError("You cannot change access rights of a Player entity.");
        }
    }
}