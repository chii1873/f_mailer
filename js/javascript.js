$(function () {

	if ($("#show_caption_1").get(0)) {
		var cookie_name = "FORM_MAILER_CAPTION";
		var form_mailer_caption = Cookies.get(cookie_name);
		if (typeof form_mailer_caption == "string" && form_mailer_caption.match(/^[01]$/)) {
			$("#show_caption_"+form_mailer_caption).click();
		} else {
			Cookies.set(cookie_name, "1", { expires: 60, path: '' });
			$("#show_caption_1").click();
		}
		$("input[name=show_caption]").on("click", function () {
			Cookies.set(cookie_name, $("input[name=show_caption]:checked").val(), { expires: 60, path: '' });
		});
	}
	$(".auto_height").each(function() {
		$(this).val().replace(/\s*,\s/g, "\n");
		$(this).css("height", (auto_height_get_lines($(this).val()) + 1) * 1.4 + "em");
	});

	$(".auto_height").bind("keyup", function() {
		$(this).val().replace(/\s*,\s/g, "\n");
		$(this).css("height", (auto_height_get_lines($(this).val()) + 1) * 1.4 + "em");
	});

	$(".reset").bind("click", function() {
		$(this).closest("form").find("textarea,:text,select").val("").end().find(":checked").prop("checked", false);
	});

	$(".charcnt_1000").charCount({
		allowed: 1000,
		warning: 20,
		counterText: "残り文字数：",
	});

	if ($("#to_page_title").get(0) && $("#to_page_title").text() != "") {
		$("#page_title").text($("#to_page_title").text());
	} else {
		$("#page_title").hide();
	}

	$("#admin_menu div").on("click", function () {
		var id = $(this).attr("id").match(/-(\d+)$/)[1];
		$("#p").val(id);
		$("#f0").submit();
	});

	$(".btn_to_menu").on("click", function () {
		if ($(this).attr("data-confirm")) {
			if (confirm("処理を中止して管理メニューに戻ります。よろしいですか？")) location.href = "f_mailer_admin.cgi";
		} else {
			location.href = "f_mailer_admin.cgi";
		}
	});
	$(".btn_submit").on("click", function () {
		var to = $(this).attr("id").match(/btn_submit_to_(\d+)/)[1];
		var flag = $(this).attr("data-confirm") == 1 ? confirm($(this).attr("data-confirm_message")) : 1;
		if (flag) {
			$("#p").val(to);
			if ($("#confid").get(0)) $("#confid").val($(this).attr("data-confid")); 
			if ($("#filename").get(0)) $("#filename").val($(this).attr("data-filename")); 
			if ($("#__token_ignore").get(0)) $("#__token_ignore").val($(this).attr("data-token_ignore") || 0); 
			if ($("#mode").get(0)) $("#mode").val($(this).attr("data-mode") || 0); 
			if ($(this).hasClass("upload")) $("#f0").attr("enctype", "multipart/form-data");
			$("#f0").submit();
		}
	});
	$("#buttonset_show_caption").controlgroup();
	$("[name=show_caption]").on("click", function () {
		caption_display_sw();
	});
	caption_display_sw();

	cond_order_init();
	$("a.cond_fname").on("click", function () {
		cond_order_set($(this).attr("data-fname"));
	});
	$(".btn_order_clear").on("click", function () {
		cond_order_clear();
	});
});

function caption_display_sw () {
	$(".caption").toggle($("#show_caption_1").prop("checked"));
}

function auto_height_get_lines (str) {

	return str.split(/\r\n|\n/).length;

}
function cond_order_init () {
	var order_max = 0;
	$(".cond_order").each(function () {
		var val = $(this).val();
		if (val.match(/\d+/) && eval(val) >= order_max) order_max = eval(val);
	});
	$("#order_max").val(order_max);
}

function cond_order_set (f) {

	var sel = "[name=order_"+f+"]";
	if ($(sel).val() != "") {
		if (eval($(sel).val()) == eval($("#order_max").val())) {
			$(sel).val("");
			$("#order_max").val(eval($("#order_max").val()) - 1);
		} else {
			alert(f + " の欄にはすでに数字が入っています。");
		}
	} else {
		$(sel).val(eval($("#order_max").val()) + 1);
		$("#order_max").val(eval($("#order_max").val()) + 1);
	}
}
function cond_order_clear() {
	$(".cond_order").val("");
	$("#order_max").val(0);
}
