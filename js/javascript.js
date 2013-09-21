function order(f) {
	if (document.getElementById("form0").elements["order_"+f].value != "") {
		if (eval(document.getElementById("form0").elements["order_"+f].value)
		 == eval(document.getElementById("form0").tmp.value)) {
			document.getElementById("form0").elements["order_"+f].value = "";
			document.getElementById("form0").tmp.value = eval(document.getElementById("form0").tmp.value)-1;
		} else {
			alert(f + " の欄にはすでに数字が入っています。");
		}
	} else {
		document.getElementById("form0").elements["order_"+f].value
		 = eval(document.getElementById("form0").tmp.value)+1;
		document.getElementById("form0").tmp.value = eval(document.getElementById("form0").tmp.value)+1;
	}
}
function order_clear() {
	for (i=0; i<document.getElementById("form0").elements.length; i++) {
		if (document.getElementById("form0").elements[i].name.match(/^order_/)) {
			document.getElementById("form0").elements[i].value = "";
		}
	}
	document.getElementById("form0").tmp.value = 0;
}
function display_sw(name) {
	if (document.getElementById(name).style.display == 'none') {
		document.getElementById(name).style.display = 'block';
	} else {
		document.getElementById(name).style.display = 'none';
	}
}

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

});

function auto_height_get_lines (str) {

	return str.split(/\r\n|\n/).length;

}
