var lang;
var current = (function() {
	if (document.currentScript) {
		return document.currentScript.src;
	} else {
		var scripts = document.getElementsByTagName('script'),
		script = scripts[scripts.length-1];
		if (script.src) {
			return script.src;
		}
	}
})();
var f_mailer_url = current.replace(new RegExp("(?:\\\/+[^\\\/]*)?$"), "/").replace(new RegExp("\\\/[^\\\/]+\\\/$"), "");
$(function () {

	if (typeof LANG === "undefined") LANG = "ja";

	$.ajaxSetup({ async: false });
	$.getJSON(f_mailer_url + "/js/lang/f_mailer_"+LANG+".json", function (data) {
		lang = data;
//		console.log(lang);
	});
	$.ajaxSetup({ async: true });
//	console.log(lang);

	// セッションIDの発行
	$.ajax({
		url: f_mailer_url + "/f_mailer.cgi",
		type: "GET",
		dataType: "json",
		async: false,
		data:{
			"CONFID": $("#CONFID").val(),
			"ajax_token": 1
		}
	})
	.done(function (d) {
		$("#__token").val(d.__token);
		file_check();
		console.log(d);
	})
	.fail(function (data) {
		alert("fail");
		console.log(data);
	});

	$(".btn_ajax_checkvalues").on("click", function () {
		$("#__token_ignore").val("1");
		$("#ajax_action").attr("name", "ajax_checkvalues").attr("value", "1");
		$.ajax({
			type: "POST",
			url: f_mailer_url + "/f_mailer.cgi",
			dataType: "json",
			async: false,
			data: $("form").serialize()
		})
		.done(function (d) {

			// 初期化
			$("*").each(function () {
				if ($(this).attr("id") && $(this).attr("id").match(/^f_mailer_errmsg-/)) $(this).text("");
			});
			$(".f_mailer_errmsg_label_bg").removeClass("f_mailer_errmsg_label_bg");
			$(".f_mailer_errmsg_bg").removeClass("f_mailer_errmsg_bg");
			$(".f_mailer_errmsg_border").removeClass("f_mailer_errmsg_border");
			$(".f_mailer_errmsg").removeClass("f_mailer_errmsg");

			// エラーがない
			if (! d.errmsg.length) {
				$("#f0").attr("target", "_self");
				$("#f0").attr("enctype", "application/x-www-form-urlencoded");
				$("#__token_ignore").val("");
				$("#ajax_action").attr("name", "DUMMY").attr("value", "");
				$("#f0").submit();
			}
			// エラーがある
			var errmsg_list = [];
			var sel = [];
			for (var i=0; i<d.errmsg.length; i++) {
				if ($.isArray(d.errmsg[i])) {
					var f_name = d.errmsg[i][0];
					var val = d.errmsg[i][1];
					if (d.FORM_TMPL_ERRMSG_DISPLAY == 2) {
						sel.push(f_name);
						$("#f_mailer_errmsg-"+f_name).text(val);
					} else {
						errmsg_list.push(val);
					}
				} else {
					errmsg_list.push(val);
				}
			}
			if (sel.length > 0) {
				for (var i=0; i<sel.length; i++) {
					$("#f_mailer_errmsg_label_bg-"+sel[i]).addClass("f_mailer_errmsg_label_bg");
					$("#f_mailer_errmsg_bg-"+sel[i]).addClass("f_mailer_errmsg_bg");
					$("#f_mailer_errmsg_border-"+sel[i]).addClass("f_mailer_errmsg_border");
					$("#f_mailer_errmsg-"+sel[i]).addClass("f_mailer_errmsg");
				}
			}
			if (errmsg_list.length > 0) {
				console.log(errmsg_list);
				var errmsg_li_style = d.ERRMSG_STYLE_LI != "" ? ' style="' + d.ERRMSG_STYLE_LI + '"' : "";
				var errmsg_li_class = d.ERRMSG_STYLE_LI_CLASS != "" ? ' class="' + d.ERRMSG_STYLE_LI_CLASS + '"' : "";
				var errmsg_ul_style = d.ERRMSG_STYLE_UL != ""  ? ' style="' + d.ERRMSG_STYLE_UL + '"' : "";
				var errmsg_ul_class = d.ERRMSG_STYLE_UL_CLASS != ""  ? ' class="' + d.ERRMSG_STYLE_UL_CLASS + '"' : "";
				var errmsg_ul_id = d.ERRMSG_STYLE_UL_ID != ""  ? ' id="' + d.ERRMSG_STYLE_UL_ID + '"' : "";
				var errmsg_html = "<ul"+ errmsg_ul_style + errmsg_ul_class + errmsg_ul_id + ">\n";
				for (var i=0; i<errmsg_list.length; i++) {
					errmsg_html += "<li" + errmsg_li_style + errmsg_li_class + ">" + errmsg_list[i] + "</li>\n";
				}
				errmsg_html += "</ul>";
				$("#f_mailer_errmsg_area").html(errmsg_html).show();
			} else {
				$("#f_mailer_errmsg_area").html("").hide();
			}
		})
		.fail(function (data) {
			alert("fail");
			console.log(data);
		});
	});

	$(".btn_submit_self").on("click", function () {
		$("#f0").attr("target", "_self");
		$("#f0").attr("enctype", "application/x-www-form-urlencoded");
		$("#__token_ignore").val("");
		$("#ajax_action").attr("name", "DUMMY").attr("value", "");
		$("#f0").submit();
	});

	$("fieldset").on("change", "input[type=file]", function () {
		var name = $(this).attr("name");
		$("#f0").attr("target", "if");
		$("#f0").attr("enctype", "multipart/form-data");
		$("#__token_ignore").val("1");
		$("#ajax_action").attr("name", "ajax_upload").attr("value", name);
		$("#f0").submit();
	});

	$("fieldset").on("click", ".btn_delete", function() {
		var name = $(this).attr("id").match(/^btn_delete-(.+)$/)[1];
		$("#f0").attr("target", "if");
		$("#f0").attr("enctype", "application/x-www-form-urlencoded");
		$("#__token_ignore").val("1");
		$("#ajax_action").attr("name", "ajax_delete").attr("value", name);
		$("#f0").submit();
	});

	$("fieldset").on("click", ".btn_upload", function () {
		var n = $(this).attr("id").match(/^btn_upload-(.+)$/)[1];
		$("#"+n).click();
	});

	$("input[type=file]").css({ "display":"inline-block", "width":"1px", "height":"1px", "overflow" : "hidden" });

	$(".btn_send_default").on("click", function () {
		$("#FORM").val("");
		$("#SEND_FORCED").val("1");
		$("#f0").submit();
	});
	$(".btn_back_default").on("click", function () {
		$("#FORM").val("1");
		$("#SEND_FORCED").val("");
		$("#f0").submit();
	});

});

function file_check() {

	$.ajax({
		type: "POST",
		url: f_mailer_url + "/f_mailer.cgi",
		dataType: "json",
		async: false,
		data: {
			"CONFID" : $("#CONFID").val(),
			"TEMP" : $("#TEMP").val(),
			"__token_ignore" : 1,
			"ajax_file_check"  : 1
		}
	})
	.done(function (d) {
		$.each(d, function(k, v) {
			if (k == "__TOTAL__") return true;
console.log(k);
			if (v.size > 0) {
//				$("#"+k).hide();
				$("#"+k).next("span").remove();
				$("#"+k).after("<span>"
					+ (
						v.size > 1024 * 1024 ? sprintf("%s (%.1fM%s)", v.name, v.size / 1024 / 1024, lang.bytes)
						: v.size > 1024 ? sprintf("%s (%.1fK%s)", v.name, v.size / 1024, lang.bytes)
						: sprintf("%s (%d%s)", v.name, v.size, lang.bytes)
					)
					+ '　<input type="button" value="' + lang.delete + '" id="btn_delete-'
					+ k + '" class="btn_delete" \/><\/span>' 
				);

			} else if ($("#"+k)) {
				$("#"+k).next("span").remove();
				$("input[type=file]#"+k).after("<span>"
					+ '<input type="button" value="' + lang.upload + '" id="btn_upload-'
					+ k + '" class="btn_upload" \/><\/span>' );
//				$("#"+k).show();
			}
		});
		$("#TEMP").val(d.TEMP);
		$(".f_mailer_upload_loading").hide();
		$(".f_mailer_upload_area").show();
	})
	.fail(function (data) {
		console.log(data);
		alert(lang.file_check_error);
	}); 

}

function upload_complete () {
	file_check();

}
