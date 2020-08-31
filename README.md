# puuuush
Deliver WebPush notifications through mobile and desktop browsers. Send notifications using shell scripts.

This is the client-side documentation for the service at [Puuuu.sh](https://puuuu.sh). You'll need to log in there with your CMU-associated Google account to start.

## Quick Start

Here's how you get started:

1. Log in at [Puuuu.sh](https://puuuu.sh) using Google Login. For now, you need an `andrew.cmu.edu` email address.
2. Set your current browser to receive notifications by clicking the "Add Sink" button on the left. Your browser will give you a security prompt.
3. Set up your current machine to send notifications by clicking the "Add Source" button. Copy the generated code and run it in Bash/Zsh/Fish/etc; it stores a bunch of shell variables in a file so you can authenticate yourself to the notification service.
4. Download the `puuuu.sh` to your drive and store it somewhere. `~/.scripts`, or `~/bin` are common places.
5. Add `source $HOME/.../puuuu.sh` to your shell config file.
6. Start a new shell session, and run the command `puuuush "Hello World" "Isn't it nice outside?"` and you should get a notification!

## Examples

You can send simple notifications with custom title and text:

```sh
puuuush "Hello World" "Isn't it nice outside?"
```

If you want to include some output (like the last line of your experiment log):

```sh
# Run experiment, saving a copy of data sent to stdout to output.txt:
./run_my_experiment.sh | tee output.txt
# Get up to 80 characters of the last line:
puuuush "Experiment Completed" $(tail -n1 output.txt | cut -c 1-80)
```

If you've already started an experiment and want to send a notification when it terminates, you can do that. Get the pid (using `ps aux`, `pidof`, `top`, etc.) and then run this:

```sh
puuush@pid 12345 "This is the message body."
```

If you've started a bunch of GPU experiments on a shared machine, and you want to know when each of them stops, you can do this:

```sh
puuush@cuda
```

This looks at the output of `nvidia-smi` and attaches a notification daemon to each `python` process owned by you that uses at least 128 MB of GPU memory. When that process completes, you will get a notification.

I encourage you to look through the script and customize it to your needs!

## Limits

There are some usage limits on this, because I don't want to have the upstream notification services annoyed at me. You can send no more than 10 notification attempts a minute, 20 an hour, and 100 a day.

This is currently limited to CMU students. Feel free to send me an email if you want to test it out.
