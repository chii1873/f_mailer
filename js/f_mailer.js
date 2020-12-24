$(function () {

	// セッションIDの発行
	$.ajax({
		url: "f_mailer.cgi",
		type: "GET",
		dataType: "json",
		async: false,
		data:{
			"CONFID": $("#CONFID").val(),
			"ajax_token": 1
		}
	})
	.done( (d) => {
		$("#__token").val(d.__token);
		file_check();
		console.log(d);
	})
	.fail( (data) => {
		alert("fail");
		console.log(data);
	});

	$(".btn_ajax_checkvalues").on("click", function () {
		$("#__token_ignore").val("1");
		$("#ajax_action").attr("name", "ajax_checkvalues").attr("value", "1");
		$.ajax({
			type: "POST",
			url: "f_mailer.cgi",
			dataType: "json",
			async: false,
			data: $("form").serialize()
		})
		.done( (d) => {

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
			let errmsg_list = [];
			let sel = [];
			for (let i=0; i<d.errmsg.length; i++) {
				if ($.isArray(d.errmsg[i])) {
					let f_name = d.errmsg[i][0];
					let val = d.errmsg[i][1];
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
				for (let i=0; i<sel.length; i++) {
					$("#f_mailer_errmsg_label_bg-"+sel[i]).addClass("f_mailer_errmsg_label_bg");
					$("#f_mailer_errmsg_bg-"+sel[i]).addClass("f_mailer_errmsg_bg");
					$("#f_mailer_errmsg_border-"+sel[i]).addClass("f_mailer_errmsg_border");
					$("#f_mailer_errmsg-"+sel[i]).addClass("f_mailer_errmsg");
				}
			}
			if (errmsg_list.length > 0) {
				console.log(errmsg_list);
				let errmsg_li_style = d.ERRMSG_STYLE_LI != "" ? ' style="' + d.ERRMSG_STYLE_LI + '"' : "";
				let errmsg_li_class = d.ERRMSG_STYLE_LI_CLASS != "" ? ' class="' + d.ERRMSG_STYLE_LI_CLASS + '"' : "";
				let errmsg_ul_style = d.ERRMSG_STYLE_UL != ""  ? ' style="' + d.ERRMSG_STYLE_UL + '"' : "";
				let errmsg_ul_class = d.ERRMSG_STYLE_UL_CLASS != ""  ? ' class="' + d.ERRMSG_STYLE_UL_CLASS + '"' : "";
				let errmsg_ul_id = d.ERRMSG_STYLE_UL_ID != ""  ? ' id="' + d.ERRMSG_STYLE_UL_ID + '"' : "";
				let errmsg_html = "<ul"+ errmsg_ul_style + errmsg_ul_class + errmsg_ul_id + ">\n";
				for (let i=0; i<errmsg_list.length; i++) {
					errmsg_html += "<li" + errmsg_li_style + errmsg_li_class + ">" + errmsg_list[i] + "</li>\n";
				}
				errmsg_html += "</ul>";
				$("#f_mailer_errmsg_area").html(errmsg_html).show();
			} else {
				$("#f_mailer_errmsg_area").html("").hide();
			}
		})
		.fail( (data) => {
			alert("fail");
			console.log(data);
		});
	});

	$(".btn_submit").on("click", function () {
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
		url: "f_mailer.cgi",
		dataType: "json",
		async: false,
		data: {
			"CONFID" : $("#CONFID").val(),
			"TEMP" : $("#TEMP").val(),
			"__token_ignore" : 1,
			"ajax_file_check"  : 1
		},
		error: function(XMLHttpRequest, textStatus, errorThrown) {
			alert(textStatus);
                },
		success: function(d) {

			$.each(d, function(k, v) {
				if (k == "__TOTAL__") return true;
console.log(k);
				if (v.size > 0) {
//					$("#"+k).hide();
					$("#"+k).next("span").remove();
					$("#"+k).after("<span>"
						+ (
							v.size > 1024 * 1024 ? sprintf("%s (%.1fMバイト)", v.name, v.size / 1024 / 1024)
							: v.size > 1024 ? sprintf("%s (%.1fKバイト)", v.name, v.size / 1024)
							: sprintf("%s (%dバイト)", v.name, v.size)
						)
						+ '　<input type="button" value="削除" id="btn_delete-'
						+ k + '" class="btn_delete" \/><\/span>' 
					);

				} else if ($("#"+k)) {
					$("#"+k).next("span").remove();
					$("input[type=file]#"+k).after("<span>"
						+ '<input type="button" value="アップロード" id="btn_upload-'
						+ k + '" class="btn_upload" \/><\/span>' );
//					$("#"+k).show();
				}
			});
			$("#TEMP").val(d.TEMP);
		}
	}); 

}

function upload_complete () {
	file_check();

}
