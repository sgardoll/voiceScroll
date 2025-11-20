import 'package:flowread/models/script.dart';

class SampleData {
  static List<Script> getSampleScripts() {
    final now = DateTime.now();
    
    return [
      Script(
        id: 'sample_1',
        title: 'Welcome Presentation',
        content: '''Good morning everyone, and welcome to today's presentation.

Today we'll be exploring the fascinating world of artificial intelligence and its impact on modern communication. As we stand at the threshold of a new technological era, it's important to understand how these advancements are shaping our daily interactions.

Artificial intelligence has revolutionized the way we process information, analyze data, and make decisions. From simple voice assistants to complex machine learning algorithms, AI has become an integral part of our digital landscape.

In this session, we'll examine three key areas: the current state of AI technology, its practical applications in various industries, and the potential challenges and opportunities that lie ahead.

Let's begin our journey into this exciting field and discover how AI is transforming the way we communicate, work, and live.

Thank you for your attention, and let's make this an engaging and informative discussion.''',
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
      
      Script(
        id: 'sample_2',
        title: 'Product Launch Speech',
        content: '''Ladies and gentlemen, distinguished guests, and valued customers.

Today marks a significant milestone in our company's journey. We are thrilled to introduce a product that will change the way you think about technology and innovation.

Our team has worked tirelessly for the past eighteen months to bring you something truly extraordinary. This isn't just another product launch. This is the beginning of a new chapter in digital transformation.

What we're unveiling today combines cutting edge design with practical functionality. It's intuitive, powerful, and built with your needs in mind.

We believe that the best technology is the kind that disappears into the background, seamlessly enhancing your daily life without getting in the way.

So without further delay, let me present to you the future of smart living. Thank you for being part of this incredible journey with us.''',
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now.subtract(const Duration(days: 3)),
      ),
      
      Script(
        id: 'sample_3',
        title: 'Conference Keynote',
        content: '''Thank you for that warm introduction. It's wonderful to be here with all of you today.

When I started my career twenty years ago, I never imagined that we would be living in a world where technology would be so deeply integrated into every aspect of our lives.

Today, I want to share with you three fundamental principles that have guided my approach to innovation and leadership throughout my career.

First, embrace change as an opportunity, not a threat. The companies and individuals who thrive are those who see disruption as a chance to grow and evolve.

Second, never underestimate the power of collaboration. The greatest breakthroughs happen when diverse minds come together to solve complex problems.

Third, remember that technology is only as good as the human problems it solves. We must always keep the end user at the center of everything we do.

These principles have served me well, and I hope they will inspire you in your own journey of innovation and growth.

Thank you.''',
        createdAt: now.subtract(const Duration(days: 7)),
        updatedAt: now.subtract(const Duration(days: 4)),
      ),
    ];
  }
}