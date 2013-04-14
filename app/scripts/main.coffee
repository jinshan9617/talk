require.config {
    paths: {
        'jquery' : '../components/jquery/jquery'
        'bootstrap' : 'vendor/bootstrap'
        'backbone' : '../components/backbone/backbone'
        'underscore' : '../components/underscore/underscore'
        'socket' : 'http://210.209.114.145:8888/socket.io/socket.io'
    }
    shim:{
        'bootstrap' : {
            deps: ['jquery']
        }
        'underscore' : {
            exports: '_'
        }
        'backbone' : {
            deps: ['underscore', 'jquery']
            exports: 'Backbone'
        }
    }
}
require ['socket','jquery','shake','underscore','backbone','htmltrans','bootstrap'],(io,$,shake,_,Backbone,htmltrans) ->
    socket = ""
    talkTab = {}
    keynum = 0
    ctrlview = {}
    $("#loading").hide()
    $("#loginput").show()
    $(".loginname").focus()
    LoginModel = Backbone.Model.extend {
        defaults : () ->
            {
                userName : ""
            }
        check : () ->
            if @get "userName"
                true
            else
                false
    }
    loginmodel = new LoginModel
    
    LoginView = Backbone.View.extend {
        el : $ ".loginpad"
        events : {
            "blur .loginname" : "changeName"
            "focus .loginname" : "changeName"
            "change .loginname" : "changeName"
            "keyup .loginname" : "changeName"
            "click #loginBtn" : "login"
        }
        initialize : () ->
            @input = @$(".loginname")
            @bar = @$("#loginbar")
            @listenTo @model,'change',@render
        changeName : () ->
            @model.set "userName",@input.val()
            @render()
        render : () ->
            if @model.check()
                @input.css "border-color","#cccccc"
                @
            else
                @input.css "border-color","red"
                @
        login : () ->
            @changeName()
            if @model.check()
                @bar.css "width","40%"
                socket = io.connect 'http://210.209.114.145:8888',{}
                @input.attr "readonly",true
                @$("button").attr "disabled",true
                socket.on 'connect',() ->
                    socket.emit 'login', {userName:$(".loginname").val()}
                    ctrlview = new ControlView
                    $("#loginbar").css "width","100%"
                    setTimeout () ->
                        loginview.destroy()
                        
                    ,500
                    @
                @
            else
                @render()
        destroy : () ->
            @$el.hide()
            $(".blackback").hide()
    }
    loginview = new LoginView {model:loginmodel}
    #msgModel
    MsgModel = Backbone.Model.extend {
        defaults : () ->
            {
                fromUser : ""
                toUser : ""
                msgText : ""
                smgType : false
                fromId : ""
                toId : ""
            }
    }
    MsgCollection = Backbone.Collection.extend {
        model : MsgModel
    }
    MsgView = Backbone.View.extend {
        initialize : () ->
            @listenTo @model, 'destroy', @remove
            @
        templateA : _.template $('#msgToMe').html()
        templateB : _.template $('#myMsg').html()
            
        render : () ->
            if @model.get "smgType"
                @$el.html @templateA(@model.toJSON())
            else
                @$el.html @templateB(@model.toJSON())
            @
       
    }

    UserModel = Backbone.Model.extend {
        defaults : () ->
            {
                userName : ""
                userId : ""
                selected : false
                newMsg : false
            }
        select : () ->
            @set "selected",true
            @set "newMsg",false
            @
    }
    UserCollection = Backbone.Collection.extend {
        model : UserModel
        selected : () ->
            @filter((usermod) ->
                usermod.get 'selected'
            )
        haveNew : () ->
            @filter((usermod) ->
                usermod.get 'newMsg'
            )
    }
    users = new UserCollection
    UserView = Backbone.View.extend {
        tagName : "button"
        className : "userBtn btn btn-block"
        template : _.template $('#userTemp').html()
        events : {
            "click" : "choose"
        }
        initialize : () ->
            @listenTo @model,"change",@render
            @listenTo @model,"destroy",@aaaa
            @
        choose : () ->
            if @model.get "selected"
                @
            else 
                if !talkTab[@model.get "userId"]
                    talkTab[@model.get "userId"] = new MsgCollection
                    @listenTo talkTab[@model.get "userId"],"add",ctrlview.addTalk
                    newId = "talk_" + @model.get("userId")
                    $(".textlayyout").append '<div id='+newId+' style="display:none;padding-bottom:20px"></div>'
                if users.selected().length
                    users.selected()[0].set "selected",false
                @model.select()
                _.each talkTab,(data,key) ->
                    $("#talk_"+key).hide()
                @
                $("#talk_"+@model.get "userId").slideDown "fast",()->
                    div = document.getElementById("textlayyout")
                    div.scrollTop = div.scrollHeight
                    @
            $(".txtarea").focus()
            @
        render : () ->
            @$el.html @template(@model.toJSON())
            #@setElement @template(@model.toJSON())
            if @model.get "selected"
                @$el.removeClass "btn-warning"
                @$el.addClass "btn-primary"
            else if @model.get "newMsg"
                @$el.addClass "btn-warning"
            else
                @$el.removeClass "btn-primary"
            @
        aaaa : () ->
            @remove()
    }
    #user test
    
    #end
    ControlView = Backbone.View.extend {
        el : $("body")
        events : {
            "click #sendBtn" : "send"
            "keydown .txtarea" : "tosend"
            "keyup .txtarea" : "keyclear"
        }
        initialize : () ->
            @input = @$(".txtarea")
            @listenTo users,"add",@addUser
            @listenTo users,"destroy",@rmUser
            socket.on "adduser",(data) ->
                _.each data,(mod,key) ->
                    if users.filter((user)->
                            user.get("userId")==mod.userId
                    ).length==0
                        users.push mod
                    @
                @
            socket.on "message",(data) ->
                data["smgType"] = true
                if talkTab[data.fromId]
                    talkTab[data.fromId].push data
                else
                    talkTab[data.fromId] = new MsgCollection
                    newId = "talk_"+data.fromId
                    $(".textlayyout").append '<div id='+newId+' style="display:none;padding-bottom:20px"></div>'
                    ctrlview.listenTo talkTab[data.fromId],"add",ctrlview.addTalk
                    talkTab[data.fromId].push data
                if users.selected()[0] and data.fromId isnt users.selected()[0].get("userId") or !users.selected()[0]
                    users.filter((usermod) ->
                        usermod.get("userId")==data.fromId
                    )[0].set "newMsg",true
                    shake.do "usr_#{data.fromId}"
                @
            $(window).unload(() ->
                socket.emit "disconnect",{a:1}
            )
            socket.on "rmuser",(data) ->
                (users.filter (mod)->
                    mod.get('userId')==data.userId
                )[0].destroy()
                @
            @
        send : () ->
            if !users.selected()
                false
            msgtxt = @input.val()
            msgtxt = htmltrans.trans msgtxt
            socket.emit "send",{msgText:msgtxt,toId:users.selected()[0].get("userId")}
            talkTab[users.selected()[0].get "userId"].push {
                fromUser : "me"
                toUser : users.selected()[0].get "userName"
                msgText : msgtxt
                smgType : false
                fromId : ""
                toId : users.selected()[0].get "userId"
            }
            @input.val("")
            @input.focus()
            @
        tosend : (e) ->
            if e.keyCode is 17
                keynum = 17
            else if e.keyCode is 13 and keynum is 17
                keynum = 0
                @send()
            else 
                keynum = 0
            @
        keyclear : () ->
            keynum = 0
            @
        addTalk : (mod) ->
            anewMsg = new MsgView {model:mod}
            divId = "talk_"+if mod.get("smgType") then mod.get("fromId") else mod.get("toId")
            $("#"+divId).append anewMsg.render().el
            div = document.getElementById("textlayyout")
            div.scrollTop = div.scrollHeight
            @
        addUser : (user) ->
            auserview = new UserView {model:user}
            @$(".userlist").append auserview.render().el
            @
        rmUser : (user) ->
            $("#talk_"+user.get "userId").remove()
    }
    
    @
    #