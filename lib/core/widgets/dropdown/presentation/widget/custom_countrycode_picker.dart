import 'package:flutter/material.dart';

class CountryData {
  final String name;
  final String dialCode;

  CountryData(this.name, this.dialCode);
}

final List<CountryData> kCountries = [
  CountryData("Afghanistan", "+93"),
  CountryData("Albania", "+355"),
  CountryData("Algeria", "+213"),
  CountryData("American Samoa", "+1-684"),
  CountryData("Andorra", "+376"),
  CountryData("Angola", "+244"),
  CountryData("Anguilla", "+1-264"),
  CountryData("Antigua and Barbuda", "+1-268"),
  CountryData("Argentina", "+54"),
  CountryData("Armenia", "+374"),
  CountryData("Aruba", "+297"),
  CountryData("Australia", "+61"),
  CountryData("Austria", "+43"),
  CountryData("Azerbaijan", "+994"),

  CountryData("Bahamas", "+1-242"),
  CountryData("Bahrain", "+973"),
  CountryData("Bangladesh", "+880"),
  CountryData("Barbados", "+1-246"),
  CountryData("Belarus", "+375"),
  CountryData("Belgium", "+32"),
  CountryData("Belize", "+501"),
  CountryData("Benin", "+229"),
  CountryData("Bermuda", "+1-441"),
  CountryData("Bhutan", "+975"),
  CountryData("Bolivia", "+591"),
  CountryData("Bosnia and Herzegovina", "+387"),
  CountryData("Botswana", "+267"),
  CountryData("Brazil", "+55"),
  CountryData("British Virgin Islands", "+1-284"),
  CountryData("Brunei", "+673"),
  CountryData("Bulgaria", "+359"),
  CountryData("Burkina Faso", "+226"),
  CountryData("Burundi", "+257"),

  CountryData("Cabo Verde", "+238"),
  CountryData("Cambodia", "+855"),
  CountryData("Cameroon", "+237"),
  CountryData("Canada", "+1"),
  CountryData("Cayman Islands", "+1-345"),
  CountryData("Central African Republic", "+236"),
  CountryData("Chad", "+235"),
  CountryData("Chile", "+56"),
  CountryData("China", "+86"),
  CountryData("Colombia", "+57"),
  CountryData("Comoros", "+269"),
  CountryData("Congo (Republic)", "+242"),
  CountryData("Congo (DRC)", "+243"),
  CountryData("Cook Islands", "+682"),
  CountryData("Costa Rica", "+506"),
  CountryData("Côte d'Ivoire", "+225"),
  CountryData("Croatia", "+385"),
  CountryData("Cuba", "+53"),
  CountryData("Curaçao", "+599"),
  CountryData("Cyprus", "+357"),
  CountryData("Czech Republic", "+420"),

  CountryData("Denmark", "+45"),
  CountryData("Djibouti", "+253"),
  CountryData("Dominica", "+1-767"),
  CountryData("Dominican Republic", "+1-809"),
  CountryData("Dominican Republic", "+1-829"),
  CountryData("Dominican Republic", "+1-849"),

  CountryData("Ecuador", "+593"),
  CountryData("Egypt", "+20"),
  CountryData("El Salvador", "+503"),
  CountryData("Equatorial Guinea", "+240"),
  CountryData("Eritrea", "+291"),
  CountryData("Estonia", "+372"),
  CountryData("Eswatini", "+268"),
  CountryData("Ethiopia", "+251"),

  CountryData("Faroe Islands", "+298"),
  CountryData("Fiji", "+679"),
  CountryData("Finland", "+358"),
  CountryData("France", "+33"),

  CountryData("Gabon", "+241"),
  CountryData("Gambia", "+220"),
  CountryData("Georgia", "+995"),
  CountryData("Germany", "+49"),
  CountryData("Ghana", "+233"),
  CountryData("Gibraltar", "+350"),
  CountryData("Greece", "+30"),
  CountryData("Greenland", "+299"),
  CountryData("Grenada", "+1-473"),
  CountryData("Guam", "+1-671"),
  CountryData("Guatemala", "+502"),
  CountryData("Guernsey", "+44-1481"),
  CountryData("Guinea", "+224"),
  CountryData("Guinea-Bissau", "+245"),
  CountryData("Guyana", "+592"),

  CountryData("Haiti", "+509"),
  CountryData("Honduras", "+504"),
  CountryData("Hong Kong", "+852"),
  CountryData("Hungary", "+36"),

  CountryData("Iceland", "+354"),
  CountryData("India", "+91"),
  CountryData("Indonesia", "+62"),
  CountryData("Iran", "+98"),
  CountryData("Iraq", "+964"),
  CountryData("Ireland", "+353"),
  CountryData("Isle of Man", "+44-1624"),
  CountryData("Israel", "+972"),
  CountryData("Italy", "+39"),

  CountryData("Jamaica", "+1-876"),
  CountryData("Japan", "+81"),
  CountryData("Jersey", "+44-1534"),
  CountryData("Jordan", "+962"),

  CountryData("Kazakhstan", "+7"),
  CountryData("Kenya", "+254"),
  CountryData("Kiribati", "+686"),
  CountryData("Kuwait", "+965"),
  CountryData("Kyrgyzstan", "+996"),

  CountryData("Laos", "+856"),
  CountryData("Latvia", "+371"),
  CountryData("Lebanon", "+961"),
  CountryData("Lesotho", "+266"),
  CountryData("Liberia", "+231"),
  CountryData("Libya", "+218"),
  CountryData("Liechtenstein", "+423"),
  CountryData("Lithuania", "+370"),
  CountryData("Luxembourg", "+352"),

  CountryData("Macao", "+853"),
  CountryData("Madagascar", "+261"),
  CountryData("Malawi", "+265"),
  CountryData("Malaysia", "+60"),
  CountryData("Maldives", "+960"),
  CountryData("Mali", "+223"),
  CountryData("Malta", "+356"),
  CountryData("Marshall Islands", "+692"),
  CountryData("Martinique", "+596"),
  CountryData("Mauritania", "+222"),
  CountryData("Mauritius", "+230"),
  CountryData("Mayotte", "+262"),
  CountryData("Mexico", "+52"),
  CountryData("Micronesia", "+691"),
  CountryData("Moldova", "+373"),
  CountryData("Monaco", "+377"),
  CountryData("Mongolia", "+976"),
  CountryData("Montenegro", "+382"),
  CountryData("Montserrat", "+1-664"),
  CountryData("Morocco", "+212"),
  CountryData("Mozambique", "+258"),
  CountryData("Myanmar", "+95"),

  CountryData("Namibia", "+264"),
  CountryData("Nauru", "+674"),
  CountryData("Nepal", "+977"),
  CountryData("Netherlands", "+31"),
  CountryData("New Caledonia", "+687"),
  CountryData("New Zealand", "+64"),
  CountryData("Nicaragua", "+505"),
  CountryData("Niger", "+227"),
  CountryData("Nigeria", "+234"),
  CountryData("Niue", "+683"),
  CountryData("North Korea", "+850"),
  CountryData("North Macedonia", "+389"),
  CountryData("Northern Mariana Islands", "+1-670"),
  CountryData("Norway", "+47"),

  CountryData("Oman", "+968"),

  CountryData("Pakistan", "+92"),
  CountryData("Palau", "+680"),
  CountryData("Panama", "+507"),
  CountryData("Papua New Guinea", "+675"),
  CountryData("Paraguay", "+595"),
  CountryData("Peru", "+51"),
  CountryData("Philippines", "+63"),
  CountryData("Poland", "+48"),
  CountryData("Portugal", "+351"),
  CountryData("Puerto Rico", "+1-787"),
  CountryData("Puerto Rico", "+1-939"),

  CountryData("Qatar", "+974"),

  CountryData("Réunion", "+262"),
  CountryData("Romania", "+40"),
  CountryData("Russia", "+7"),
  CountryData("Rwanda", "+250"),

  CountryData("Saint Helena", "+290"),
  CountryData("Saint Kitts and Nevis", "+1-869"),
  CountryData("Saint Lucia", "+1-758"),
  CountryData("Saint Pierre and Miquelon", "+508"),
  CountryData("Saint Vincent and the Grenadines", "+1-784"),
  CountryData("Samoa", "+685"),
  CountryData("San Marino", "+378"),
  CountryData("São Tomé and Príncipe", "+239"),
  CountryData("Saudi Arabia", "+966"),
  CountryData("Senegal", "+221"),
  CountryData("Serbia", "+381"),
  CountryData("Seychelles", "+248"),
  CountryData("Sierra Leone", "+232"),
  CountryData("Singapore", "+65"),
  CountryData("Sint Maarten", "+1-721"),
  CountryData("Slovakia", "+421"),
  CountryData("Slovenia", "+386"),
  CountryData("Solomon Islands", "+677"),
  CountryData("Somalia", "+252"),
  CountryData("South Africa", "+27"),
  CountryData("South Korea", "+82"),
  CountryData("South Sudan", "+211"),
  CountryData("Spain", "+34"),
  CountryData("Sri Lanka", "+94"),
  CountryData("Sudan", "+249"),
  CountryData("Suriname", "+597"),
  CountryData("Sweden", "+46"),
  CountryData("Switzerland", "+41"),
  CountryData("Syria", "+963"),

  CountryData("Taiwan", "+886"),
  CountryData("Tajikistan", "+992"),
  CountryData("Tanzania", "+255"),
  CountryData("Thailand", "+66"),
  CountryData("Timor-Leste", "+670"),
  CountryData("Togo", "+228"),
  CountryData("Tokelau", "+690"),
  CountryData("Tonga", "+676"),
  CountryData("Trinidad and Tobago", "+1-868"),
  CountryData("Tunisia", "+216"),
  CountryData("Turkey", "+90"),
  CountryData("Turkmenistan", "+993"),
  CountryData("Turks and Caicos Islands", "+1-649"),
  CountryData("Tuvalu", "+688"),

  CountryData("Uganda", "+256"),
  CountryData("Ukraine", "+380"),
  CountryData("United Arab Emirates", "+971"),
  CountryData("United Kingdom", "+44"),
  CountryData("United States", "+1"),
  CountryData("Uruguay", "+598"),
  CountryData("Uzbekistan", "+998"),

  CountryData("Vanuatu", "+678"),
  CountryData("Vatican City", "+39"),
  CountryData("Vatican City", "+379"),
  CountryData("Venezuela", "+58"),
  CountryData("Vietnam", "+84"),

  CountryData("Yemen", "+967"),

  CountryData("Zambia", "+260"),
  CountryData("Zimbabwe", "+263"),
];

Future<void> showCustomCountryPicker({
  required BuildContext context,
  required ValueChanged<CountryData> onSelect,
  List<CountryData>? countries,
}) {
  final all = countries ?? kCountries;
  final searchController = TextEditingController();
  List<CountryData> filtered = List.from(all);

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      return StatefulBuilder(builder: (context, setState) {
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.78,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.arrow_back),
                  color: Colors.black,
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search, color: Colors.white70),
                      hintText: "Search country",
                      hintStyle: TextStyle(color: Colors.white54),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                    onChanged: (q) {
                      setState(() {
                        filtered = all
                            .where((c) =>
                        c.name.toLowerCase().contains(q.toLowerCase()) ||
                            c.dialCode.contains(q))
                            .toList();
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // black rounded container holding the list — matches your screenshot
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => Divider(color: Colors.white12, height: 1),
                      itemBuilder: (context, index) {
                        final country = filtered[index];
                        return InkWell(
                          onTap: () {
                            Navigator.of(context).pop();
                            onSelect(country);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    country.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),

                                // RIGHT: dial code
                                Text(
                                  country.dialCode,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      });
    },
  );
}





class AccountData {
  final String account;

  AccountData(this.account);
}


final List<AccountData> kAccounts = [
  AccountData("+93 87654321"),
  AccountData("+91 9876543210"),
  AccountData("+91 9876543210"),
  AccountData("+91 9876543210"),

  AccountData("example@mail.com"),
  AccountData("user@gmail.com"),
  AccountData("user@gmail.com"),
  AccountData("user@gmail.com"),

];

Future<void> showAccountPickerDialog({
  required BuildContext context,
  required ValueChanged<AccountData> onSelect,
  List<AccountData>? accounts,
}) {
  final all = accounts ?? kAccounts;

  return showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: all.length,
            separatorBuilder: (_, __) =>
                Divider(color: Colors.white, height: 1),
            itemBuilder: (context, index) {
              final item = all[index];

              return ListTile(
                title: Text(
                  item.account,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  onSelect(item);
                },
              );
            },
          ),
        ),
      );
    },
  );
}
