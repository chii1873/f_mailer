$(function() {
	$("#tabs").tabs({
		activate: function( event, ui ) {
			$("#tabs-3A").show();
			$("#tabs-3B").hide();
		}
	});
	$(".btn_mail_format_type_1").on("click", function () {
		$("#mail_format_type_1").dialog({ title: "タイプ1", width: 500 });
	});
	$(".btn_mail_format_type_2").on("click", function () {
		$("#mail_format_type_2").dialog({ title: "タイプ2", width: 500 });
	});
	$(".btn_mail_format_type_3").on("click", function () {
		$("#mail_format_type_3").dialog({ title: "タイプ3", width: 500 });
	});
	$(".btn_mail_format_type_0").on("click", function () {
		$("#mail_format_type_0").dialog({ title: "フォーマット内で指定できる差し込み用文字列", width: 800 });
	});
	$(".btn_subject").on("click", function () {
		$("#mail_format_type_0").dialog({ title: "件名内で指定できる差し込み用文字列", width: 800 });
	});
	$(".btn_output_filename").on("click", function () {
		$("#output_filename").dialog({ title: "書き出すファイル名で指定できる差し込み用文字列", width: 400 });
	});

	$("[name=FILE_OUTPUT],[name=DO_NOT_SEND],[name=AUTO_REPLY]").on("click", function () {
		display_sw_p111();
	});
	display_sw_p111();
//	$("#tbl-tab3 tbody").sortable();
	$(".output_fields_pool").sortable({
		connectWith: ".output_fields_pool",
		update: function () {
			output_fields_set();
		}
	});
	output_fields_set();
	$("#label").on("keyup blur", function () {
		set_label_dsp();
	});
	set_label_dsp();
	$(document).on("click", ".btn_cond_o", function () {
		var i = $(this).attr("id").match(/(\d+)$/)[1];
		$("#cond_other"+i).dialog({
			title: "フィールド名："+$("#cond_fname"+i).text()+" のその他の条件設定",
			width: 800,
			modal: true,
			overlay: { backgroundColor: "#000", opacity: 0.8 },
			buttons: { "閉じる": function() {
				set_cond_o_status();
				$(this).dialog("destroy");
			}},
			close: function (event, ui) {
				set_cond_o_status();
				$(this).dialog("destroy");
			}
		});
	});
	set_cond_o_status();
	$("#FORMAT").on("change", function () {
		$("#MAIL_FORMAT_TYPE_0").click();
	});
	$("#REPLY_FORMAT").on("change", function () {
		$("#REPLY_MAIL_FORMAT_TYPE_0").click();
	});
	$(document).on("change", ".cond_alt", function () {
		output_fields_name_update();
	});
	$(".btn_field_import").on("click", function () {
		$("#tabs-3A").hide();
		$("#tabs-3B_errmsg").html("");
		$("#tabs-3B").show();
		$("#import_method_1").click();
		$("#import_method_url,#import_method_source").val("");
	});
	$("#btn_import_method_cancel").on("click", function () {
		$("#tabs-3A").show();
		$("#tabs-3B").hide();
	});
	$("#btn_import_method_do").on("click", function () {
		$("#p").val("104");
		$("#__token_ignore").val("1");
		$.ajax({
			url: "f_mailer_admin.cgi",
			type: "POST",
			dataType: "json",
			async: false,
/*
			data:{
				p: 104,
				__token: $("#__token").val(),
				__token_ignore: 1,
				import_method: ($("#import_method_1").prop("checked") ? 1 : $("#import_method_2").prop("checked") ? 2 : ""),
				import_method_url: $("#import_method_url").val(),
				import_method_source: $("#import_method_source").val()
			}
*/
			data: $("#f0").serialize()
		})
		.done( (d) => {
			// テーブルと並び替えパーツの更新
			if (d.succeeded == 1) {
				$("#tbl-tab3 tbody").html(d.cond_list);
				$("#cond_other").html(d.cond_other);
				$("#output_fields_pool1").html(d.output_fields_pool1);
				$("#output_fields_pool0").html(d.output_fields_pool0);
				$("#cond").val(d.cond);
				output_fields_set();
				set_cond_o_status();
				$("#tabs-3A").show();
				$("#tabs-3B").hide();
				$("#tabs-3B_errmsg").html("");

			// エラーメッセージの表示
			} else {
				var html = '<ul class="errmsg">' + "\n";
				for (var i=0; i< d.errmsg.length; i++) {
					html += "<li>" + d.errmsg[i] + "</li>\n"
				}
				html += "<ul>";
				$("#tabs-3B_errmsg").html(html);
			}
			console.log(d);
		})
		.fail( (data) => {
			alert("fail");
			console.log(data);
		});
	});
	$("#import_method_url").on("change", function () {
		if ($("#import_method_url").val() != "") $("#import_method_1").click();
	});
	$("#import_method_source").on("change", function () {
		if ($("#import_method_source").val() != "") $("#import_method_2").click();
	});
});
function display_sw_p111 () {
	$("#tbl-tab4").toggle($("#DO_NOT_SEND_0").prop("checked"));
	$("#tbl-tab5").toggle($("#AUTO_REPLY_1").prop("checked"));
	$("#tbl-tab6").toggle($("#FILE_OUTPUT_1").prop("checked"));
}
function output_fields_set () {
	var output_fields = [];
	$("#output_fields_pool1 li").each(function () {
		output_fields.push($(this).attr("data-fname"));
	});
	$("#OUTPUT_FIELDS").val(output_fields.join(","));
}
function output_fields_name_update () {
	$("#output_fields_pool1 li,#output_fields_pool0 li").each(function () {
		var fname = $(this).attr("data-fname");
		$(this).text( $("[name=_cond_alt_"+fname+"]").val() + "(" + fname + ")" );
	});
}
function set_cond_o_status () {
	$(".cond_o_status").each(function () {
		var i = $(this).attr("id").match(/(\d+)$/)[1];
		var is_set = 0;
		$("#cond_other"+i+" input").each(function () {
			var f = $(this).attr("class").split(/ /)[0];
			if ($(this).attr("type") == "checkbox") {
				if ($("#"+f+"_"+i).prop("checked")) is_set = 1;
			} else if ($("#"+f+"_"+i).val() != "") is_set = 1;
		});
		$("#cond_o_status"+i).attr("src", is_set ? "img/checkbox_checked.png" : "img/checkbox_unchecked.png");
	});
}
function set_label_dsp () {
	var s = $("#label").val();
	if (s == "") s = "(指定されていません)";
	$("#label_dsp").text(s);
}
