$(function() {

	$("#chkall").on("click", function () {
		is_chk_all = sel_all_chk();
		$("[name=chk]").prop("checked", is_chk_all ? false : true);
	});
	$("[name=chk]").on("click", function () {
		is_chk_all = sel_all_chk();
		$("#chkall").prop("checked", is_chk_all ? true : false);
	});

});

function sel_all_chk () {
	is_chk_all = 1;
	$("[name=chk]").each(function () {
		if ($(this).prop("checked") == false) {
			is_chk_all = 0;
			return false;
		}
	});
	return is_chk_all;
}
