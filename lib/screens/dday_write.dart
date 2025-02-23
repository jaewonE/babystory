import 'dart:io';

import 'package:babystory/models/diary.dart';
import 'package:babystory/models/parent.dart';
import 'package:babystory/providers/parent.dart';
import 'package:babystory/screens/create_post.dart';
import 'package:babystory/screens/dday.dart';
import 'package:babystory/screens/diary.dart';
import 'package:babystory/utils/alert.dart';
import 'package:babystory/utils/http.dart';
import 'package:babystory/widgets/appbar/simple_closed_appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class DdayWriteScreen extends StatefulWidget {
  int diaryId;
  DateTime createTime;

  DdayWriteScreen({super.key, required this.diaryId, required this.createTime});

  @override
  State<DdayWriteScreen> createState() => _DdayWriteScreenState();
}

class _DdayWriteScreenState extends State<DdayWriteScreen> {
  final HttpUtils httpUtils = HttpUtils();
  final TextEditingController _titleController = TextEditingController();
  late Parent parent;

  List<ContentBlock> contentBlocks = [];

  @override
  void initState() {
    super.initState();
    parent = getParentFromProvider();
    // 빈 텍스트 블록으로 시작
    contentBlocks.add(ContentBlock(text: ""));
  }

  @override
  void dispose() {
    super.dispose();
    _titleController.dispose();
    for (var block in contentBlocks) {
      block.dispose();
    }
  }

  Parent getParentFromProvider() {
    final parent = context.read<ParentProvider>().parent;
    if (parent == null) {
      throw Exception('Parent is null');
    }
    return parent;
  }

  Future<void> saveStory() async {
    String title = _titleController.text.trim();
    if (title.isEmpty) {
      // 에러 메시지 표시
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제목을 입력해주세요.')),
      );
      return;
    }

    String totalContent = '';
    List<File> imageFiles = []; // 이미지 파일 목록
    int imageCount = 1;
    for (int i = 0; i < contentBlocks.length; i++) {
      if (contentBlocks[i].text != null &&
          contentBlocks[i].text!.trim().isNotEmpty) {
        totalContent += contentBlocks[i].text ?? '';
      } else if (contentBlocks[i].imageFile != null) {
        totalContent += '![[tempddayId-$imageCount]]';
        imageCount++;
        imageFiles.add(contentBlocks[i].imageFile!);
      }
      totalContent += '\n';
    }

    if (totalContent.isEmpty) {
      // 에러 메시지 표시
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('내용을 입력해주세요.')),
      );
      return;
    }

    try {
      var json = await httpUtils.post(url: '/dday/create', headers: {
        'Authorization': 'Bearer ${parent.jwt}'
      }, body: {
        'diary_id': widget.diaryId,
        'title': title,
        'content': totalContent,
        'createTime':
            "${widget.createTime.year}-${widget.createTime.month}-${widget.createTime.day}",
      });
      print("Response json: $json");
      var ddayId = json?['dday']?['dday_id'];
      if (ddayId == null) {
        debugPrint('create diary failed');
        throw Exception('create diary failed');
      }
      // if ddayId is string, convert to int
      if (ddayId is String) {
        ddayId = int.parse(ddayId);
      }

      // ddayId 추가.
      totalContent = totalContent.replaceAll('![[tempddayId', '![[$ddayId');

      // 이미지 업로드
      if (imageFiles.isNotEmpty) {
        var imageJson = await httpUtils.postMultiImages(
            url: '/dday/photoUpload/$ddayId',
            headers: {'Authorization': 'Bearer ${parent.jwt}'},
            images: imageFiles);
        print("Response imageJson: $imageJson");
        if (imageJson == null || imageJson['success'] != 200) {
          debugPrint('upload image failed');
          throw Exception('upload image failed');
        }
      }

      await alertSuccessAndNavigate(ddayId);
    } catch (e) {
      debugPrint(e.toString());
      alertError();
      return;
    }
  }

  Future<void> alertSuccessAndNavigate(int ddayId) async {
    if (mounted) {
      await Alert.asyncAlert(
        context: context,
        title: "일기 생성 완료",
        content: "일기가 성공적으로 작성되었습니다.",
        onAccept: (dialogContext) async {
          Navigator.of(dialogContext).pushReplacement(
            MaterialPageRoute(
              builder: (ctx) => DdayScreen(ddayId: ddayId),
            ),
          );
        },
      );
    }
  }

  void alertError() {
    if (mounted) {
      Alert.alert(
          context: context,
          title: "문제 발생",
          content: "일기 생성에 실패하였습니다. 잠시 후에 다시 시도해주세요.");
    }
  }

  void addImage() async {
    // 현재 포커스된 텍스트 필드의 인덱스 가져오기
    int index =
        contentBlocks.indexWhere((block) => block.focusNode?.hasFocus == true);
    if (index == -1) {
      // 포커스된 텍스트 필드가 없을 경우 마지막에 이미지 추가
      index = contentBlocks.length - 1;
      // 마지막 블록이 이미지인 경우 텍스트 블록 추가
      if (contentBlocks[index].imageFile != null) {
        contentBlocks.add(ContentBlock(text: ""));
        index = contentBlocks.length - 1;
      }
    } else {
      // 커서 위치에서 텍스트 분할
      final block = contentBlocks[index];
      final controller = block.controller!;
      final text = controller.text;
      final cursorPos = controller.selection.baseOffset;

      if (cursorPos < 0 || cursorPos > text.length) {
        // 커서 위치가 유효하지 않을 경우 끝으로 설정
        controller.selection =
            TextSelection.fromPosition(TextPosition(offset: text.length));
      }

      final beforeText = text.substring(0, cursorPos);
      final afterText = text.substring(cursorPos);

      // 현재 텍스트 블록 업데이트
      block.text = beforeText;
      controller.text = beforeText;

      // 커서 이후의 텍스트가 있을 경우 새로운 텍스트 블록 생성
      if (afterText.isNotEmpty) {
        final newTextBlock = ContentBlock(text: afterText);
        contentBlocks.insert(index + 1, newTextBlock);
        index += 1; // 인덱스 조정
      }
    }

    // 이미지 선택
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        // 이미지 블록 삽입
        contentBlocks.insert(
            index + 1, ContentBlock(imageFile: File(image.path)));
        // 이미지 이후에 빈 텍스트 블록 추가
        final newTextBlock = ContentBlock(text: "");
        contentBlocks.insert(index + 2, newTextBlock);

        // 새로운 텍스트 필드에 포커스 설정
        Future.delayed(const Duration(milliseconds: 100), () {
          FocusScope.of(context).requestFocus(newTextBlock.focusNode);
        });
      });
    }
  }

  void changeImage(int index) async {
    // 이미지 선택
    final ImagePicker picker = ImagePicker();
    final XFile? newImage = await picker.pickImage(source: ImageSource.gallery);
    if (newImage != null) {
      setState(() {
        contentBlocks[index].imageFile = File(newImage.path);
      });
    }
  }

  void handleImageLongPress(int index) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('이미지 삭제'),
                onTap: () {
                  setState(() {
                    contentBlocks[index].dispose();
                    contentBlocks.removeAt(index);
                  });
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.image),
                title: const Text('이미지 변경'),
                onTap: () {
                  Navigator.of(context).pop();
                  changeImage(index);
                },
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('취소'),
                onTap: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void closeKeyboard() {
    // 키보드가 올라와 있는 경우 숨기기
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: SimpleClosedAppBar(
        title: '일기 쓰기',
        iconAction: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const DiaryScreen(),
            ),
          );
        },
        rightIcon: Icons.check_rounded,
        rightIconAction: () => saveStory(),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // 제목 입력
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      controller: _titleController,
                      decoration: const InputDecoration.collapsed(
                        hintText: '제목',
                      ),
                    ),
                  ),
                  const Divider(height: 2, color: Color.fromARGB(58, 0, 0, 0)),
                  // 콘텐츠 입력 영역
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: contentBlocks.map((block) {
                        if (block.text != null) {
                          // 텍스트 블록
                          final controller = block.controller!;
                          final focusNode = block.focusNode!;
                          return TextField(
                            controller: controller,
                            focusNode: focusNode,
                            decoration: InputDecoration.collapsed(
                              hintText:
                                  contentBlocks.length == 1 ? '내용을 입력하세요' : '',
                            ),
                            maxLines: null,
                            onChanged: (value) {
                              block.text = value;
                            },
                          );
                        } else if (block.imageFile != null) {
                          // 이미지 블록
                          final index = contentBlocks.indexOf(block);
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: GestureDetector(
                              onLongPress: () => handleImageLongPress(index),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8.0),
                                child: Image.file(block.imageFile!),
                              ),
                            ),
                          );
                        } else {
                          return const SizedBox.shrink();
                        }
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 하단 도구 모음
          Container(
            width: MediaQuery.of(context).size.width,
            color: const Color.fromARGB(255, 250, 250, 250),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(
                      Icons.photo_outlined,
                      color: Colors.black87,
                      size: 18,
                    ),
                    onPressed: addImage,
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(
                      Icons.keyboard_hide_outlined,
                      color: Colors.black87,
                      size: 18,
                    ),
                    onPressed: closeKeyboard,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
