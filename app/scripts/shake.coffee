define () ->
	t = {}
	shake  = (dId) ->
	    w = $("#"+dId)
	    t[dId] = setInterval () ->
		    w.css "position","relative"
		    w.animate {top:"-10px"},"fast"
		    w.animate {top:"10px"},"fast"
		    w.animate {top:"-5px"},"fast"
		    w.animate {top:"5px"},"fast"
		    w.animate {top:"0"},"fast"
		    @
	    ,2000
    stop = (dId) ->
    	t[dId]&&clearInterval t[dId]
    	@
	do:shake,
	stop:stop