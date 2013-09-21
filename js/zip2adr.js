/*
* 郵便番号→住所 変換スクリプト（google maps API 使用）
* Author : Takeshi Tomida @ UNISON INNOVATION
* 2013.04.07 create
* 2013.04.07 reconstruct
*/

(function($) {
    $.fn.zip2adr = function(zip,callback){
        var cb   = (arguments.length > 1) ? true : false;
        
        if(zip === ''){
            return false;
        }
        
        var target = $(this);
        
        $.ajax({
            type : 'get',
            url : 'http://maps.googleapis.com/maps/api/geocode/json',
            crossDomain : true,
            dataType : 'json',
            data : {
                address : zip,
                language : 'ja',
                sensor : false
            },
            success : function(resp){
                if(resp.status == "OK"){   
                    var obj = resp.results[0].address_components;
                    var adrSize = obj.length -1;
//alert(obj[adrSize].long_name);
                    if (obj[adrSize].short_name != "JP") return false;
                    switch(cb){
                        case true: // コールバック関数があるとき
                            var respObj = {};
                            respObj.pref = obj[adrSize - 1].long_name;
                            
                            respObj.below = ''; 
                            for(i=adrSize - 2;i > 0; i --){
                                respObj.below += obj[i].long_name;
                            }
                            
                            respObj.adr = respObj.pref + respObj.below;
                            
                            callback(respObj);
                            break;
                        case false: // コールバック無し
                            var tmp = '';
                            for(i=adrSize - 1;i > 0; i --){
                                tmp += obj[i].long_name;
                            }
                            target.val(tmp);                            
                            break;
                        default:
                            return false;
                    }
                    
                }else{
                    return false;
                }
            }
        });
    };
})(jQuery);
