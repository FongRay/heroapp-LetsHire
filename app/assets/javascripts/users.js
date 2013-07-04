(function ($, tmpst) {
    'use strict';

    var page = {
        reloadDepartmentUsers: function (elem, department_id, callback) {
            elem.load('/users/index_for_selection' + '?department_id=' + department_id, function (response, status) {
                if (status == 'success') {
                    if (callback) {
                        callback();
                    }
                }
            });
        }
    };

    tmpst.usersPage = page;
}(jQuery, tmpst));