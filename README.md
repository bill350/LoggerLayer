# LoggerLayer

**Make your logs flexbile &amp; scalable for your product and your team!**

Example of a Logger Layer in an iOS Swift project. 

## Context

Today, apps become more and more complexes, with big teams & production monitoring. 
So, you have to structure your app efficiently and make your team flexible at the same time.

Logs are essential too: create boards on Datadog or any Cloud Platform, create alerts, log non-fatal errors. They are here to make your real-time production analysis faster than ever before.

To do it, here we create a Logger layer, to be able to change, add or remove any destinations or third party library around the app logging; all of this, without change your original logger calls across your app & modules.

### Modular app

![](./resources/project-structure.png)

### Console logs

![](./resources/project-console-log.png)

### NSLogger logs filtering

![](./resources/nslogger.png)

### OSLog

Console.app & Instruments

![](./resources/console-app.png)

![](./resources/instruments.png)

### Etc.

## The talk & slides

The original idea of this architecture is from [my talk at Cocoaheads Paris](https://www.meetup.com/fr-FR/CocoaHeads-Paris/events/fgvkkqyxpblb/) of November 2018.

You can see the slides [here]().

## Author

Jean-Charles SORIN, iOS Lead at [BackMarket](backmarket.com).

[Follow me!](https://twitter.com/jcsorin)