import 'package:babystory/models/baby.dart';
import 'package:babystory/models/baby_state_record.dart';
import 'package:babystory/models/perent.dart';
import 'package:babystory/screens/add_baby.dart';
import 'package:babystory/screens/setting.dart';
import 'package:babystory/utils/color.dart';
import 'package:babystory/widgets/add_baby_card.dart';
import 'package:babystory/widgets/baby_info_card.dart';
import 'package:babystory/widgets/horizontal_swiper_cards.dart';
import 'package:babystory/widgets/user_profile_widget.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  final Perent perent;
  const ProfileScreen({super.key, required this.perent});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late List<Baby> babies;

  @override
  void initState() {
    babies = [
      Baby(
        name: '아기1',
        birthDate: DateTime.now(),
        perent: widget.perent,
        state: BabyStateRecord(
          recordDate: DateTime.now(),
          title: 'initialize state',
          description: 'initialize state',
        ),
      )
    ];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(top: 40, bottom: 10),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Profile',
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: ColorProps.textBlack),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (context) => const SettingScreen())),
                        icon: const Icon(Icons.settings),
                        color: ColorProps.textBlack,
                      )
                    ],
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  UserProfileWidget(perent: widget.perent),
                  const SizedBox(
                    height: 48,
                  ),
                ],
              ),
            ),
            HorizontalSwiperCards(
              viewportFraction: 0.9,
              cardGap: 6,
              height: 452,
              cards: List.generate(babies.length + 1, (index) {
                if (index == babies.length) {
                  return GestureDetector(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => const AddBabyScreen())),
                    child: const AddBabyCard(),
                  );
                }
                return BabyInfoCard(baby: babies[index]);
              }),
            )
          ],
        ),
      ),
    );
  }
}