import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    double size = MediaQuery.sizeOf(context).width;
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          Center(
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      padding: EdgeInsets.only(top: 8),
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(),
                      child: GestureDetector(
                        onTap: () {
                          //Image Picker
                        },
                        child: CircleAvatar(
                          child: Image.asset(
                            'assets/images/403024_avatar_boy_male_user_young_icon.png',
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: -11,
                      bottom: -12,
                      child: IconButton(
                        onPressed: () {
                          //Image Picker
                        },
                        icon: Icon(Icons.add_circle),
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    //Image Picker
                  },
                  child: Text("Edit"),
                ),
                SizedBox(height: 15),
                SingleChildScrollView(
                  child: Card(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    clipBehavior: null,
                    margin: EdgeInsets.all(5),
                    child: Column(
                      children: [
                        inputFields("Name", "Aregbe Ayomide"),
                        SizedBox(),
                        inputFields('Username', "haywhyzero24"),
                        SizedBox(),
                        inputFields('Email', "aregbeayomide@gmail.com"),
                        SizedBox(),
                        inputFields('Country', ""),
                        SizedBox(height: 15),
                  
                        SizedBox(
                          width: size - 25,
                          child: ElevatedButton(
                            style: ButtonStyle(
                              backgroundColor: WidgetStateColor.resolveWith(
                                (ctx) => const Color(0xFF53698A),
                              ),
                            ),
                            onPressed: () {},
                            child: Text(
                              "Update",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget inputFields(String title, String value) {
    double size = MediaQuery.sizeOf(context).width;
    bool readOnly = true;
    final controller = TextEditingController(text: value);
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title),
          SizedBox(height: 5),
          Container(
            width: size - 20,
            height: 35,
            decoration: BoxDecoration(
              // border: Border.all(
              //   color: Colors.black38,
              // )
            ),
            child: TextField(
              controller: controller,
              readOnly: readOnly,
              enableInteractiveSelection: !readOnly,
              style: TextStyle(color: readOnly ? Colors.grey[400] : null, fontSize: 14),
              decoration: InputDecoration(
                contentPadding: EdgeInsets.all(5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      if (readOnly) {
                      readOnly = false;
                      Future.delayed(const Duration(milliseconds: 50), () {
                        FocusScope.of(context).requestFocus(FocusNode());
                      },);
                    } else {
                      readOnly = true;
                      controller.text;
                      FocusScope.of(context).unfocus();
                    }
                      
                    });
                    
                  },
                  icon: Icon(readOnly ? Icons.edit_outlined : Icons.done, size: 16, color: Theme.of(context).brightness == Brightness.light
              ? Colors.black38
              : Colors.white54,),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
