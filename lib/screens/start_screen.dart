// lib/screens/start_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_state.dart';
import '../screens/game_board_screen.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  int _selectedPlayerCount = 2;
  late List<TextEditingController> _nameControllers;
  bool _playWithBot = false;

  @override
  void initState() {
    super.initState();
    _nameControllers = List.generate(4, (index) => TextEditingController(text: 'Oyuncu ${index + 1}'));
  }

  @override
  void dispose() {
    for (var controller in _nameControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _startGame() {
    List<String> playerNames;
    bool hasBot = _playWithBot;

    if (_playWithBot) {
      playerNames = [_nameControllers[0].text, 'Bot'];
    } else {
      playerNames = List.generate(
        _selectedPlayerCount,
        (index) => _nameControllers[index].text.trim().isEmpty 
            ? 'Oyuncu ${index + 1}' 
            : _nameControllers[index].text.trim()
      );
    }

    context.read<GameState>().startGame(playerNames: playerNames, hasBot: hasBot);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const GameBoardScreen()),
    );
  }

  // --- YENİ: Profesyonel Metin Giriş Alanı Widget'ı ---
  Widget _buildPlayerNameField(int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 8),
      child: TextField(
        controller: _nameControllers[index],
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white, fontSize: 18), // Yazı rengi ve boyutu
        decoration: InputDecoration(
          // Metin alanı arka planı
          filled: true,
          fillColor: Colors.black.withOpacity(0.3),
          
          // İpucu metni stili
          hintText: 'Oyuncu ${index + 1} İsmi',
          hintStyle: TextStyle(color: Colors.grey[400]),
          
          // Normal kenarlık
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: Colors.blueGrey[700]!, width: 1.5),
          ),
          
          // Tıklanınca oluşan kenarlık
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(color: Color(0xFF536dfe), width: 2.0),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // --- GÜNCELLENDİ: Ana arkaplan rengi ve genel tema ---
    return Scaffold(
      backgroundColor: const Color(0xFF1a2a4e), // Koyu ve modern bir arkaplan
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Text('DUOPOLY', style: Theme.of(context).textTheme.displayLarge),
                const SizedBox(height: 40),
                
                // --- GÜNCELLENDİ: Switch stili ---
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12)
                  ),
                  child: SwitchListTile.adaptive(
                    title: const Text('Bota Karşı Oyna', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    value: _playWithBot,
                    onChanged: (bool value) {
                      setState(() {
                        _playWithBot = value;
                        if (_playWithBot) {
                          _selectedPlayerCount = 2;
                        }
                      });
                    },
                    activeColor: const Color(0xFF536dfe),
                    activeTrackColor: const Color(0xFF536dfe).withOpacity(0.5),
                    inactiveThumbColor: Colors.grey,
                    inactiveTrackColor: Colors.grey.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 30),

                if (!_playWithBot) ...[
                  Text('Oyuncu Sayısını Seçin', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [2, 3, 4].map((count) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        // --- GÜNCELLENDİ: Chip stili ---
                        child: ChoiceChip(
                          label: Text('$count Oyuncu', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          selected: _selectedPlayerCount == count,
                          onSelected: (isSelected) {
                            if (isSelected) {
                              setState(() { _selectedPlayerCount = count; });
                            }
                          },
                          backgroundColor: Colors.black.withOpacity(0.3),
                          selectedColor: const Color(0xFF536dfe),
                          shape: StadiumBorder(side: BorderSide(color: Colors.blueGrey[700]!)),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 30),
                
                // --- GÜNCELLENDİ: İsim girdileri yeni widget ile oluşturuluyor ---
                ...List.generate(_playWithBot ? 1 : _selectedPlayerCount, (index) {
                  return _buildPlayerNameField(index);
                }),
                
                const SizedBox(height: 40),

                // --- GÜNCELLENDİ: Buton stili ---
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF536dfe),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 15),
                    textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    elevation: 5,
                  ),
                  onPressed: _startGame,
                  child: const Text('Oyuna Başla'),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}