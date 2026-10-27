import 'package:flutter/material.dart';

class PracticeOneScreen extends StatelessWidget {
  const PracticeOneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Phần thực hành số 1')),
      body: const SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Center(child: PavlovaCard()),
        ),
      ),
    );
  }
}

class PavlovaCard extends StatelessWidget {
  const PavlovaCard({super.key});

  @override
  Widget build(BuildContext context) {
    // Keep the two-child Row on phones too; scroll horizontally when needed.
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.clamp(960.0, 1080.0).toDouble();
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: width,
            child: Card(
              color: Colors.white,
              elevation: 0,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: const BorderSide(color: Color(0xFFCCCCCC)),
              ),
              clipBehavior: Clip.antiAlias,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 620),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        width: width * 0.43,
                        decoration: const BoxDecoration(
                          border: Border(
                            right: BorderSide(color: Color(0xFFCCCCCC)),
                          ),
                        ),
                        child: const PavlovaDetails(),
                      ),
                      Expanded(
                        child: Image.asset(
                          'assets/images/pavlova.jpg',
                          fit: BoxFit.cover,
                          semanticLabel: 'Pavlova với dâu tây và kem tươi',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class PavlovaDetails extends StatelessWidget {
  const PavlovaDetails({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          RecipePanel(
            minHeight: 60,
            child: RecipeText(text: 'Strawberry Pavlova', isTitle: true),
          ),
          RecipePanel(
            minHeight: 230,
            child: RecipeText(
              text:
                  'Pavlova is a meringue-based dessert named after the Russian '
                  'ballerina Anna Pavlova. Pavlova features a crisp crust and '
                  'soft, light inside, topped with fruit and whipped cream.',
            ),
          ),
          RecipePanel(minHeight: 60, child: Review()),
          RecipePanel(minHeight: 110, child: RecipeFacts()),
        ],
      ),
    );
  }
}

class RecipePanel extends StatelessWidget {
  const RecipePanel({super.key, required this.child, required this.minHeight});

  final Widget child;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: minHeight),
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFCCCCCC)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Center(child: child),
    );
  }
}

class RecipeText extends StatelessWidget {
  const RecipeText({super.key, required this.text, this.isTitle = false});

  final String text;
  final bool isTitle;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: isTitle ? 22 : 17,
        fontWeight: isTitle ? FontWeight.bold : FontWeight.normal,
        height: 1.35,
      ),
    );
  }
}

/// User input and mutable review data live only in this widget.
class Review extends StatefulWidget {
  const Review({super.key});

  @override
  State<Review> createState() => _ReviewState();
}

class _ReviewState extends State<Review> {
  int _rating = 0;
  int _reviewCount = 170;

  void _submitRating(int rating) {
    setState(() {
      // Changing the same user's rating must not count as another review.
      if (_rating == 0) _reviewCount++;
      _rating = rating;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(5, (index) {
                final rating = index + 1;
                return SizedBox(
                  width: 32,
                  height: 48,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    tooltip: 'Đánh giá $rating sao',
                    onPressed: () => _submitRating(rating),
                    icon: Icon(
                      _rating == 0 || rating <= _rating
                          ? Icons.star
                          : Icons.star_border,
                      color: _rating == 0 ? Colors.grey : Colors.green,
                      size: 24,
                    ),
                  ),
                );
              }),
            ),
            Flexible(
              child: TextButton(
                onPressed: () => _submitRating(_rating == 0 ? 5 : _rating),
                child: Text('$_reviewCount Reviews'),
              ),
            ),
          ],
        ),
        if (_rating > 0)
          Text(
            'Bạn đã đánh giá $_rating/5 sao',
            style: const TextStyle(color: Colors.green, fontSize: 13),
          ),
      ],
    );
  }
}

class RecipeFacts extends StatelessWidget {
  const RecipeFacts({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        RecipeFact(icon: Icons.kitchen, label: 'PREP:', value: '25 min'),
        RecipeFact(icon: Icons.timer_outlined, label: 'COOK:', value: '1 hr'),
        RecipeFact(icon: Icons.restaurant, label: 'FEEDS:', value: '4-6'),
      ],
    );
  }
}

class RecipeFact extends StatelessWidget {
  const RecipeFact({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.green),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 12),
        Text(value),
      ],
    );
  }
}
