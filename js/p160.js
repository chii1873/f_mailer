__CHANGED = 0;
$(function() {

	$("#tabs").tabs();
	$("#tabs-2 table input[type=radio],#tabs-2 table input[type=checkbox]").on("click", function () {
		disabled_sw();
	});
	__init();
	disabled_sw();

	$("#btn_iterate").on("click", function () {
		gen_data();
	});

	$("#USERDATA").on("change keyup blur", function () {
		$(this).val($(this).val().replace(/\t/g,","));
	});
	$("#USERDATA").on("change", function () {
		__CHANGED = 1;
		$("#btn_submit_ajax_to_162").prop("disabled", false);
	});

	$("#btn_submit_ajax_to_162").on("click", function () {
		var btn = $(this);
		Swal.fire({
			"text": "ID・ユニークキーを更新します。よろしいですか？",
			"icon": "warning",
			"showCancelButton": true,
			"confirmButtonText": `はい`,
			"cancelButtonText": `いいえ`,
		})
		.then(function(result) {
			if (result.isConfirmed) {
				submit_ajax(162, {
					"confid": btn.data("confid"),
					"__token_ignore": 1,
					"USERDATA": $("#USERDATA").val()
				});
				if (__CHANGED == 0) $("#btn_submit_ajax_to_162").prop("disabled", true);
			}
		});
	});
	$("#btn_submit_ajax_to_163").on("click", function () {
		var btn = $(this);
		Swal.fire({
			"text": "回答済みフラグをすべてリセットします。よろしいですか？",
			"showCancelButton": true,
			"confirmButtonText": `はい`,
			"cancelButtonText": `いいえ`,
		})
		.then(function(result) {
			if (result.isConfirmed) {
				submit_ajax(163, {
					"confid": btn.data("confid"),
					"__token_ignore": 1
				});
			}
		});
	});

});

function __init () {

	$("#iterator_method_id_2").prop("checked", true);
	$("#iterator_method_pw_1").prop("checked", true);
	$("#iterator_method_key_1").prop("checked", true);
	$("#iterator_prefix_id").val("user");
	$("#iterator_digits_id").val("4");
	$("#iterator_digits_pw").val("8");
	$("#iterator_digits_key").val("12");
	$("#iterator_charn_id").prop("checked", true);
	$("#iterator_charl_id,#iterator_charu_id,#iterator_charc_id").prop("checked", false);
	$("#iterator_charn_pw,#iterator_charl_pw,#iterator_charu_pw").prop("checked", true);
	$("#iterator_charc_pw").prop("checked", false);
	$("#iterator_charn_key,#iterator_charl_key,#iterator_charu_key").prop("checked", true);
	$("#iterator_charc_key").prop("checked", false);

}

function disabled_sw () {

	var mode = ["id", "pw", "key"];

	for (var i=1; i<=mode.length; i++) {
		var m = mode[ i - 1 ].toLowerCase();
		if ($("#iterator_generate_"+m).prop("checked")) {
			$(".col"+i+" input").prop("disabled", false);
			$("#iterator_charc_"+m+",#iterator_charl_"+m+",#iterator_charu_"+m).prop("disabled", $("#iterator_method_"+m+"_1").prop("checked") ? false : true);
			$("#iterator_prefix_"+m).prop("disabled", $("#iterator_method_"+m+"_2").prop("checked") ? false : true);
			$("#iterator_charo_"+m).prop("disabled", $("#iterator_method_"+m+"_1").prop("checked") && $("#iterator_charc_"+m).prop("checked") ? false : true);

			if ($("#iterator_method_"+m+"_2").prop("checked") == true) {
				$("#iterator_charc_"+m+",#iterator_charl_"+m+",#iterator_charu_"+m).prop("checked", false);
				$("#iterator_charn_"+m).prop("checked", true);
			}

		} else {
			$(".col"+i+" input").prop("disabled", true);

		}
	}
}

function do_reset() {

	if (confirm("回答済みフラグをすべてリセットします。よろしいですか?")) {
		document.getElementById("f1").submit();
	}

}

function gen_data () {

	var mode = ["id", "pw", "key"];
	var mode_dsp = ["ログインID", "パスワード", "ユニークキー"];

	var errmsg = [];

	if ($("#iterator_number").val() == "") {
		errmsg.push("アカウント個数を指定してください。");
	} else if ($("#iterator_number").val().match(/[^0-9]/)) {
		errmsg.push("アカウント個数は半角数字で指定してください。");
	} else if ($("#iterator_number").val().value == "0") {
		errmsg.push("アカウント個数は1以上の値を指定してください。");
	}
	if (errmsg.length > 0) {
		swal_errmsg(errmsg);
		return;
	}

	var columns = [];

	for (var i=1; i<=mode.length; i++) {
		var m = mode[ i - 1 ];
		var m_dsp = mode_dsp[ i - 1 ];

		if ($("#iterator_generate_"+m).prop("checked") == false) continue;

		columns.push(m.toUpperCase());

		if ($("#iterator_method_"+m+"_1").prop("checked") == false && $("#iterator_method_"+m+"1").prop("checked") == false) {
			errmsg.push(m_dsp + "の生成方法を選択してください。");
		}
		if ($("#iterator_digits_"+m).val() == "") {
			errmsg.push(m_dsp + "のケタ数を指定してください。");
		} else if ($("#iterator_digits_"+m).val().match(/[^0-9]/)) {
			errmsg.push(m_dsp + "のケタ数は半角数字で指定してください。");
		} else if ($("#iterator_digits_"+m).val().value == "0") {
			errmsg.push(m_dsp + "のケタ数は1以上の値を指定してください。");
		}

		if (
			$("#iterator_charn_"+m).prop("checked") == false
			&& $("#iterator_charl_"+m).prop("checked") == false
			&& $("#iterator_charu_"+m).prop("checked") == false
			&& $("#iterator_charc_"+m).prop("checked") == false
		) {
			errmsg.push(m_dsp + "の使用文字種を指定してください。");
		}

		if ($("#iterator_charc_"+m).prop("checked") == true) {
			if ($("#iterator_charo_"+m).val() == "") {
				errmsg.push(m_dsp + "のカスタム文字列を指定してください。");
			} else if ($("#iterator_charo_"+m).val().match(/[^0-9a-zA-Z\-_]/)) {
				errmsg.push(m_dsp + "のカスタム文字列に使用できない文字が含まれています。");
			}
		}
	}
	if (errmsg.length > 0) {
		swal_errmsg(errmsg);
		return;
	}
	if (columns.length == 0) {
		swal_errmsg(errmsg);
	}

	var keylist = new Array(parseInt($("#iterator_number").val()));
	var result = [];
	var col_idx = 0;
	for (var i=1; i<=mode.length; i++) {
		var m = mode[ i - 1 ];
		var m_dsp = mode_dsp[ i - 1 ];

		if ($("#iterator_generate_"+m).prop("checked") == false) continue;

		var charlist = [];
		if ($("#iterator_charn_"+m).prop("checked") == true) {
			for (j=48; j<58; j++) {
				charlist.push(String.fromCharCode(j));
			}
		}
		if ($("#iterator_charu_"+m).prop("checked") == true) {
			for (j=65; j<91; j++) {
				charlist.push(String.fromCharCode(j));
			}
		}
		if ($("#iterator_charl_"+m).prop("checked") == true) {
			for (j=97; j<123; j++) {
				charlist.push(String.fromCharCode(j));
			}
		}
		if ($("#iterator_charc_"+m).prop("checked") == true) {
			var str = $("#iterator_charo_"+m).val().replace(/[^0-9a-zA-Z\-_]/g, "");
			for (j=0; j<str.length; j++) {
				charlist.push(str.charAt(j));
			}
		}

		charlist = array_unique(charlist);
//console.log(charlist);

		var allcnt = Math.pow(charlist.length, parseInt($("#iterator_digits_"+m).val())) - ($("#iterator_method_"+m+"_1").prop("checked") ? 0 : 1);
		if (allcnt < parseInt($("#iterator_number").val())) {
			swal_errmsg([m_dsp + "のアカウント個数を、指定された使用文字種で可能な総組み合わせ数("+allcnt+")以下に設定してください。"]);
			return false;
		}

		var done = [];
		for (j=0; j<parseInt($("#iterator_number").val()); j++) {
			var cnt = 0;
			if (typeof keylist[j] === "undefined") keylist[j] = [];
			while (1) {
				var s = "";
				if ($("#iterator_method_"+m+"_1").prop("checked")) {
					for (k=0; k<parseInt($("#iterator_digits_"+m).val()); k++) {
						s = s + charlist[Math.floor(Math.random()*charlist.length)];
					}
				} else {
					s = $("#iterator_prefix_"+m).val() + ("000000000000000000000000" + (1 + j)).slice(-1 * parseInt($("#iterator_digits_"+m).val()));
				}
				if (!done[s]) {
					done[s] = 1;
					keylist[j][col_idx] = s;
					break;
				}
				if (cnt++ > 100000) {
					break;
				}
			}
		}
		col_idx++;
	}

//console.log(keylist);
	for (j=0; j<parseInt($("#iterator_number").val()); j++) {
		result = result + keylist[j].join("\t") + "\n";
	}

	$("#iterator_result").val(columns.join("\t") + "\n" + result);

}

function array_unique (Arr) {
	var storeArr = new Array;
	var ret = new Array;
	var i = 0;
	var f = 0;
	while (Arr[i] != null) {
		if (Arr[i] != "") {
			if (storeArr[String(Arr[i])]) {
			} else {
				storeArr[String(Arr[i])] = 1;
				ret[f] = Arr[i];
				f++;
			}
		}
		i++;
	}
	return ret;
}
function swal_errmsg (msg) {
	Swal.fire({
		"text": msg,
		"icon": "error"
	});
}
function swal_info (msg) {
	Swal.fire({
		"text": msg,
		"icon": "info"
	});
}

function submit_ajax (p, data) {
	data["p"] = p;
	$.ajax({
		"url": "f_mailer_admin.cgi",
		"type": "POST",
		"dataType": "json",
		"async": false,
		"data": data
	})
	.done(function (d) {
		if (d.info != "") {
			swal_info(d.info);
			__CHANGED = 0;
		} else if (d.errmsg != "") {
			swal_errmsg(d.errmsg);
		}
	})
	.fail(function (data) {
		console.log(data);
		swal_errmsg("submit_ajax: failed: see sonsole log for detail");
	});
	return 0;
}
