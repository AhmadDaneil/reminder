import 'package:flutter/material.dart';
import 'package:reminder/services/settings_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  void _showColorPicker(BuildContext context, {
    required Color initialColor,
    required void Function(Color) onColorSelected,
    required String title,
  }) {
    Color pickerColor = initialColor;

    showDialog(
      context: context, 
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: pickerColor,
            onColorChanged: (color) => pickerColor = color,
            enableAlpha: false,
            labelTypes: [],
            pickerAreaHeightPercent: 0.8,
          ),
        ),
        actions: [
          TextButton(
          onPressed: ()=> Navigator.of(context).pop(),
          child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: (){
              onColorSelected(pickerColor);
              Navigator.of(context).pop();
            },
            child: const Text('Select'),
          )
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: settings.appBarColor,
        title: Text(
          'Settings',
          style: TextStyle(
            color: settings.fontColor
          ),
          ),
        centerTitle: true,
        iconTheme: IconThemeData(color: settings.fontColor),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text('App Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color:Theme.of(context).textTheme.bodyMedium!.color)),
            SwitchListTile(
              value: settings.isDarkmode, 
              onChanged: (val) => settings.toggleDarkMode(),
              title: Text('Dark Mode', style: TextStyle(color:Theme.of(context).textTheme.bodyMedium!.color)),
              ),
              DropdownButtonFormField<String>(
                value: settings.fontSize,
                items: ['Small', 'Default', 'Medium', 'Large'].map((e) => DropdownMenuItem(value: e, child: Text(e, style: TextStyle(color: settings.fontColor, fontSize: settings.fontSizeValue, fontWeight: FontWeight.bold,
                ),
                ),
                ))
                .toList(), 
                onChanged: (val) {
                  if (val != null) settings.setFontSize(val);
                },
                dropdownColor: settings.backgroundColor,
                style: TextStyle(color: settings.fontColor),
                decoration: InputDecoration(
                  labelText: 'Font Size',
                  labelStyle: TextStyle(color: settings.fontColor),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: settings.fontColor)
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: settings.fontColor)
                  )
                  ),
              ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: () {
              _showColorPicker(context, initialColor: settings.backgroundColor, onColorSelected: settings.setBackgroundColor, title: 'Select Background Color',
              );
            },
            child: const Text('Choose Background Color'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: () {
              _showColorPicker(context, initialColor: settings.fontColor, onColorSelected: settings.setFontColor, title: 'Select Font Color',
              );
            },
            child: const Text('Choose Font Color'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: () {
              _showColorPicker(context, initialColor: settings.appBarColor, onColorSelected: settings.setAppBarColor, title: 'Select title Color',
              );
            },
            child: const Text('Choose Title Color'),
            ),
            const SizedBox(height:50),
            Center(
              child: Text(
              'Version: 1.0.0',
              style: TextStyle(color: settings.fontColor, fontWeight: FontWeight.bold, fontSize: 15,),
              ),
            ),
          ],
        ),
      ),
    );
  }
}