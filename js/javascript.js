$(function () {

	$(".auto_height").each(function() {
		$(this).val().replace(/\s*,\s/g, "\n");
		$(this).css("height", (auto_height_get_lines($(this).val()) + 1) * 1.2 + "em");
	});

	$(".auto_height").bind("keyup", function() {
		$(this).val().replace(/\s*,\s/g, "\n");
		$(this).css("height", (auto_height_get_lines($(this).val()) + 1) * 1.2 + "em");
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

});

function auto_height_get_lines (str) {

	return str.split(/\r\n|\n/).length;

}
