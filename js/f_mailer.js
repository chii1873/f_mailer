$(function () {

	$(".btn_submit").on("click", function () {
		$("#f0").attr("target", "_self");
		$("#f0").attr("enctype", "application/x-www-form-urlencoded");
		$("#ajax_action").attr("name", "DUMMY").attr("value", "");
		$("#f0").submit();
	});

	$("fieldset").on("change", "input[type=file]", function () {
		var name = $(this).attr("name");
		$("#f0").attr("target", "if");
		$("#f0").attr("enctype", "multipart/form-data");
		$("#ajax_action").attr("name", "ajax_upload").attr("value", name);
		$("#f0").submit();
	});

	$("fieldset").on("click", ".btn_delete", function() {
		var name = $(this).attr("id").match(/^btn_delete-(.+)$/)[1];
		$("#f0").attr("target", "if");
		$("#f0").attr("enctype", "application/x-www-form-urlencoded");
		$("#ajax_action").attr("name", "ajax_delete").attr("value", name);
		$("#f0").submit();
	});

	$("fieldset").on("click", ".btn_upload", function () {
		var n = $(this).attr("id").match(/^btn_upload-(.+)$/)[1];
		$("#"+n).click();
	});

	$("input[type=file]").css({ "display":"inline-block", "width":"1px", "height":"1px", "overflow" : "hidden" });

	file_check();

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
			"ajax_file_check"  : 1
		},
		error: function(XMLHttpRequest, textStatus, errorThrown) {
			alert(textStatus);
                },
		success: function(d) {

			$.each(d, function(k, v) {
				if (k == "__TOTAL__") return true;
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
