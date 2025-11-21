public with sharing class UtilDate {
    public static Map<Integer,String> MONTHS_SHORT_NAMES = new Map<Integer,String>{
        1 => 'Jan',
        2 => 'Feb',
        3 => 'Mar',
        4 => 'Apr',
        5 => 'May',
        6 => 'Jun',
        7 => 'Jul',
        8 => 'Aug',
        9 => 'Sep',
        10 => 'Oct',
        11 => 'Nov',
        12 => 'Dec'
    };

    public static String getMonthShortName(Date d) {
        return MONTHS_SHORT_NAMES.get(d?.month());
    }
}